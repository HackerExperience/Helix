defmodule Helix.Story do

  alias Helix.Story
  alias Helix.Story.Step
  alias Helix.Story.Steppable

  def step_handler(event) do
    current_step =
      event
      |> Step.get_entity()
      |> MissionQuery.get_current_step()

    if current_step do
      current_step
      |> Step.new(event)
      |> Story.step_flow()
    end
  end

  # TODO: Add meta so we can filter with relevant ids, say, to ensure the
  # downloaded file is the one I'm expecting
  def step_flow(step) do
    case Steppable.handle_event(step, step.event, %{meta: :foo}) do
      {:complete, step} ->
        with {:ok, step} <- Steppable.complete(step) do
          next_step = Steppable.next_step(step)
          update_next(step, next_step)
        end

      {:fail, step} ->
        Steppable.fail(step)

      {:noop, _} ->
        :noop
    end
  end

  defp update_next(prev_step, next_step_module) do
    # Call next_step_module.`setup`
    # Modify Player's current step to be NextStep
  end
end
