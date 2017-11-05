defmodule Helix.Process.Event.Handler.Process do

  alias Helix.Event
  alias Helix.Process.Action.Process, as: ProcessAction

  alias Helix.Process.Event.Process.Completed, as: ProcessCompletedEvent

  def process_completed(event = %ProcessCompletedEvent{}) do
    case event.action do
      :delete ->
        ProcessAction.delete(event.process)
    end
  end
end
