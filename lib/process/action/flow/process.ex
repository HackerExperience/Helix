defmodule Helix.Process.Action.Flow.Process do

  import HELF.Flow

  alias Helix.Event
  alias Helix.Process.Model.Process
  alias Helix.Process.Action.Process, as: ProcessAction

  def signal(process = %Process{}, signal, params) do
    flowing do
      with {:ok, events} <- ProcessAction.signal(process, signal, params) do
        Event.emit(events)
      end
    end
  end
end
