defmodule Helix.Process.Event.Handler.Process do

  alias Helix.Event
  alias Helix.Process.Action.Process, as: ProcessAction

  alias Helix.Process.Event.Process.Completed, as: ProcessCompletedEvent
  alias Helix.Process.Event.Process.Signaled, as: ProcessSignaledEvent

  def signal_handler(event = %ProcessSignaledEvent{}) do
    event.action
    |> action_handler(event.process, event.params)
    |> Enum.map(&(Event.set_process_id(&1, event.process.process_id)))
    |> Event.emit(from: event)
  end

  defp action_handler(:delete, process, %{reason: reason}) do
    {:ok, events} = ProcessAction.delete(process, reason)

    events
  end

  # defp action_handler(:pause, process, _) do
  #   {:ok, events} = ProcessAction.pause(process)

  #   events
  # end
end
