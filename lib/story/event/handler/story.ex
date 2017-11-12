defmodule Helix.Story.Event.Handler.Story do
  @moduledoc """
  The StoryEventHandler is centralized, in the sense that all events that should
  be handled by Steps must get handled by it.

  Once an event is received, we figure out the entity responsible for that event
  and verify whether the StepFlow should be followed. The StepFlow guides the
  Step through the Steppable protocol, allow it to react to the event, either
  by ignoring it, completing the step or failing it.
  """

  import HELF.Flow
  import HELL.Macros

  alias Helix.Event
  alias Helix.Story.Action.Story, as: StoryAction
  alias Helix.Story.Model.Step
  alias Helix.Story.Model.Steppable
  alias Helix.Story.Query.Story, as: StoryQuery

  @doc """
  Main step handler. Its first role is to figure out the entity that event
  belongs to, and then fetching that entity's current step.

  If an step is found, we instantiate its object (Steppable data/struct), and
  guide it through the StepFlow. See doc on `step_flow/1`

  Emits:
  - Events returned by `Steppable` methods
  - StepProceededEvent.t when action is :complete
  - StepFailedEvent.t, StepRestartedEvent.t when action is :fail
  """
  def step_handler(event) do
    with \
      entity_id = %{} <- Step.get_entity(event),
      step = %{} <- StoryQuery.fetch_current_step(entity_id)
    do
      step.object
      |> Step.new(event)
      |> step_flow()
    end
  end

  docp """
  The StepFlow guides the step, allowing it to react to the received event.

  Step handling of events is made through Steppable's `handle_event/3`, refer to
  its documentation for more information.

  Once the event is handled by the step, the returned action is handled by
  StepFlow. It may be one of `:complete | :fail | :noop`. See doc on
  `handle_action/2`.
  """
  defp step_flow(step) do
    flowing do
      with \
        {action, step, events} <-
          Steppable.handle_event(step, step.event, step.meta),
        on_success(fn -> Event.emit(events) end),
        handle_action(action, step)
      do
        :ok
      end
    end
  end

  @spec handle_action(Steppable.actions, Step.t(struct)) ::
    term
  docp """
  When a step requests to be completed, we'll call `Steppable.complete/1`,
  get the next step's name and then update on the database using `update_next/2`
  """
  defp handle_action(:complete, step) do
    with {:ok, step, events} <- Steppable.complete(step) do
      Event.emit(events)

      next_step = Step.get_next_step(step)
      hespawn fn ->
        update_next(step, next_step)
      end
    end
  end

  docp """
  If the request is to fail/abort an step, we'll call `Steppable.fail/1`,
  and then handle the failure with `fail_step/1`
  """
  defp handle_action(:fail, step) do
    with {:ok, step, events} <- Steppable.fail(step) do
      Event.emit(events)

      hespawn fn ->
        fail_step(step)
      end
    end
  end

  docp """
  Received action `:noop`, so we do nothing
  """
  defp handle_action(:noop, _),
    do: :noop

  @spec update_next(Step.t(struct), Step.step_name) ::
    term
  docp """
  Updates the database, so that the player gets moved to the next step.

  This is where we call next step's `Steppable.setup`, as well as the
  `StepProceededEvent` is sent to the client

  Emits: StepProceededEvent.t
  """
  defp update_next(prev_step = %{entity_id: entity_id}, next_step_name) do
    next_step = Step.fetch(next_step_name, entity_id, %{})

    flowing do
      with \
        {:ok, _} <- StoryAction.proceed_step(prev_step, next_step),
        # /\ Proceeds player to the next step

        # Generate next step data/meta
        {:ok, next_step, events} <- Steppable.setup(next_step, prev_step),
        on_success(fn -> Event.emit(events) end),

        # Update step meta
        {:ok, _} <- StoryAction.update_step_meta(next_step),

        # Notify about step progress
        event = StoryAction.notify_step(prev_step, next_step),
        on_success(fn -> Event.emit(event) end)
      do
        :ok
      end
    end
  end

  docp """
  See comments & implement me.

  Emits: StepFailedEvent.t, StepRestartedEvent.t
  """
  defp fail_step(_step) do
    # Default fail_step implementation is TODO.
    # Possible implementation:
    #   1 - Remove all emails/replies sent through that step
    #   2 - Undo/delete all objects generated on `Steppable.setup`*
    #   3 - Call `Steppable.setup`, effectively restarting the step.
    #
    # Possible problems:
    #   1 - Email/reply ids are not unique across steps, so step 1 should take
    #     this into consideration.
    #   /\ - add counter of emails sent during the current step
    #
    #   2 - UX: If mission is reset right after it's failed, the client may
    #     receive the `stepproceeded**` event almost at the same time as
    #     `stepfailed` event, so user experience should be considered
    #   /\ - see note; use `StepRestartedEvent`
    #
    # Notes:
    # * - This should be done at `Steppable.fail`
    # ** - In fact, mission "resetup" should be a different event, maybe
    #   `StepRestarted`. Otherwise, the client would get `StepProceeded` after
    #   the step has failed, which doesn't quite make sense.
  end
end
