defmodule Helix.Story.Event.Handler.Story do

  import HELF.Flow
  import HELL.MacroHelpers

  alias Helix.Event
  alias Helix.Story.Action.Story, as: StoryAction
  alias Helix.Story.Model.Step
  alias Helix.Story.Model.Steppable
  alias Helix.Story.Query.Story, as: StoryQuery

  def step_handler(event) do
    step =
      event
      |> Step.get_entity()
      |> StoryQuery.fetch_current_step()

    if step do
      step.object
      |> Step.new(event)
      |> step_flow()
    end
  end

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

  @spec handle_action(:complete | :fail | :noop, Step.t(struct)) ::
    term
  defp handle_action(:complete, step) do
    with {:ok, step, events} <- Steppable.complete(step) do
      Event.emit(events)

      next_step = Step.get_next_step(step)
      hespawn fn ->
        update_next(step, next_step)
      end
    end
  end
  defp handle_action(:fail, step),
    do: Steppable.fail(step)
  defp handle_action(:noop, _),
    do: :noop

  @spec update_next(Step.t(struct), Step.step_name) ::
    term
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
end
