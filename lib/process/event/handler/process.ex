defmodule Helix.Process.Event.Handler.Process do

  alias Helix.Event
  alias Helix.Process.Action.Process, as: ProcessAction

  alias Helix.Process.Event.Process.Completed, as: ProcessCompletedEvent
  alias Helix.Process.Event.Process.Signaled, as: ProcessSignaledEvent

  def process_completed(event = %ProcessCompletedEvent{}),
    do: action_handler(event.action, event.process)

  def signal_handler(event = %ProcessSignaledEvent{}),
    do: action_handler(event.action, event.process)

  defp action_handler(action, process) do
    case action do
      :delete ->
        ProcessAction.delete(process)
    end
  end
end
