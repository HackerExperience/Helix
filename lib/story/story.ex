defmodule Helix.Story do

  alias Helix.Story
  alias Helix.Story.Step
  alias Helix.Story.Steppable

  def step_handler(event) do
    current_step =
      event
      |> get_entity()
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
    with \
      {:ok, step} <- Steppable.filter_event(step),
      {:ok, step} <- Steppable.complete(step)
    do
      update_next(Steppable.next_step(step))
    end
  end

  defp get_entity(%_{source_entity_id: entity_id}),
    do: entity_id

  defp update_next(next_step) do
    IO.puts "udpate next"
    IO.inspect(next_step)
  end
end
