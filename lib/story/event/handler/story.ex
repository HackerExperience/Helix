defmodule Helix.Story.Event.Handler.Story do
  @moduledoc """
  The StoryEventHandler is centralized, in the sense that all events that should
  be handled by Steps must get handled by it.

  Once an event is received, we figure out the entity responsible for that event
  and verify whether the StepFlow should be followed. The StepFlow guides the
  Step through the Steppable protocol, allow it to react to the event, either
  by ignoring it, completing the step or restarting it.
  """

  import HELF.Flow
  import HELL.Macros

  alias Helix.Event
  alias Helix.Story.Action.Story, as: StoryAction
  alias Helix.Story.Model.Step
  alias Helix.Story.Model.Steppable
  alias Helix.Story.Model.Story
  alias Helix.Story.Query.Story, as: StoryQuery

  alias Helix.Story.Event.Step.ActionRequested, as: StepActionRequestedEvent

  @doc """
  Main step handler. Its first role is to figure out the entity that event
  belongs to, and then fetching any steps that entity is assigned to.

  For each step found, we instantiate its object (Steppable data/struct), and
  guide it through the StepFlow. See doc on `step_flow/2`

  Emits:
  - Events returned by `Steppable` methods
  - StepProceededEvent.t when action is :complete
  - StepRestartedEvent.t when action is :restart
  """
  def event_handler(event) do
    with \
      entity_id = %{} <- Step.get_entity(event),
      steps = [_] <- StoryQuery.get_steps(entity_id)
    do
      Enum.each(steps, fn %{object: step, entry: story_step} ->
        step
        |> Step.new(event)
        |> step_flow(story_step)
      end)
    end
  end

  @doc """
  Handler for `StepActionRequestedEvent`, directly relaying the requested action
  to the corresponding handler at `handle_action/2`.
  """
  def action_handler(event = %StepActionRequestedEvent{}) do
    with \
      %{object: step, entry: story_step} <-
        StoryQuery.fetch_step(event.entity_id, event.contact_id)
    do
      step = Step.new(step, event)

      handle_action(event.action, step, story_step)
    end
  end

  docp """
  The StepFlow guides the step, allowing it to react to the received event.

  Step handling of events is made through Steppable's `handle_event/3`, refer to
  its documentation for more information.

  Once the event is handled by the step, the returned action is handled by
  StepFlow. It may be one of `:complete | {:restart, _, _} | :noop`. See doc on
  `handle_action/2`.
  """
  defp step_flow(step, story_step) do
    flowing do
      with \
        {action, step, events} <-
          Steppable.handle_event(step, step.event, step.meta),

        # HACK: Workaround for HELF #29
        # on_success(fn -> Event.emit(events, from: step.event) end),
        Event.emit(events, from: step.event),
        handle_action(action, step, story_step)
      do
        :ok
      end
    end
  end

  @spec handle_action(Step.callback_action, Step.t, Story.Step.t) ::
    term
  docp """
  When a step requests to be completed, we'll call `Steppable.complete/1`,
  get the next step's name and then update on the database using `update_next/2`
  """
  defp handle_action(:complete, step, story_step),
    do: handle_action({:complete, []}, step, story_step)
  defp handle_action({:complete, opts}, step, _story_step) do
    with {:ok, step, events} <- Steppable.complete(step) do
      emit(events, opts, from: step.event)

      next_step = Step.get_next_step(step)
      hespawn fn ->
        update_next(step, next_step)
      end
    end
  end

  docp """
  If the request is to restart a step, we'll call `Steppable.restart/3`, and
  then handle the restart with `restart_step/1`.
  """
  defp handle_action({:restart, reason, checkpoint}, step, _story_step) do
    with \
      {:ok, step, meta, events} <- Steppable.restart(step, reason, checkpoint),
      emit(events, from: step.event),

      :ok <- restart_step(step, reason, checkpoint, meta)
    do
      :ok
    end
  end

  docp """
  The requested action may be to send an email, which is handled here.

  This action does not use or depends on `Steppable`.
  """
  defp handle_action({:send_email, email_id, meta, opts}, step, _story_step) do
    with {:ok, events} <- StoryAction.send_email(step, email_id, meta) do
      emit(events, opts, from: step.event)

      :ok
    end
  end

  docp """
  The requested action may be to send a reply, which is handled here.

  This action does not use or depends on `Steppable`.
  """
  defp handle_action({:send_reply, reply_id, opts}, step, story_step) do
    with {:ok, events} <- StoryAction.send_reply(step, story_step, reply_id) do
      emit(events, opts, from: step.event)

      :ok
    end
  end

  docp """
  Received action `:noop`, so we do nothing
  """
  defp handle_action(:noop, _, _),
    do: :noop

  @spec update_next(Step.t, Step.step_name) ::
    term
  docp """
  Updates the database, so that the player gets moved to the next step.

  This is where we call next step's `Steppable.start`, as well as make sure the
  `StepProceededEvent` is sent to the client.

  Emits: StepProceededEvent.t
  """
  defp update_next(prev_step, next_step_name) do
    next_step =
      Step.fetch(next_step_name, prev_step.entity_id, %{}, prev_step.manager)

    with \
      true <- next_step_name != prev_step.name,
      # /\ If `next_step` == `prev_step`, we've reached the end of the story

      # Proceeds player to the next step
      {:ok, _} <- StoryAction.proceed_step(prev_step, next_step),

      # Generate next step data/meta
      {:ok, next_step, events, opts} <- Steppable.start(next_step),
      emit(events, opts, from: prev_step.event),

      # Update step meta
      {:ok, _} <- StoryAction.update_step_meta(next_step),

      # Notify about step progress
      event = StoryAction.notify_step(prev_step, next_step),
      Event.emit(event, from: prev_step.event)
    do
      :ok
    end
  end

  docp """
  Updates the database, so the step restart is persisted.

  It will:
  - update the DB with the new step metadata
  - rollback the emails to the specified checkpoint
  - notify the client that the step has been restarted

  Emits: StepRestartedEvent.t
  """
  defp restart_step(step, reason, checkpoint, meta) do
    with \
      {:ok, _} <- StoryAction.update_step_meta(step),
      # /\ Make sure the step metadata is updated on the DB

      # Rollback to the specified checkpoint
      {:ok, _, _} <- StoryAction.rollback_emails(step, checkpoint, meta),

      # Notify about step restart
      event = StoryAction.notify_restart(step, reason, checkpoint, meta),
      Event.emit(event, from: step.event)
    do
      :ok
    end
  end

  docp """
  Helper that interprets the emission parameters defined at `send_opts` (if any)
  and makes sure they are followed.
  """
  defp emit(event, from: source_event),
    do: emit(event, [], from: source_event)
  defp emit(event, [], from: source_event),
    do: Event.emit(event, from: source_event)
  defp emit(event, [sleep: 0], from: source_event),
    do: emit(event, from: source_event)
  defp emit(event, [sleep: interval], from: source_event),
    do: Event.emit_after(event, interval * 1000, from: source_event)
end
