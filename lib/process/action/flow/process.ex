defmodule Helix.Process.Action.Flow.Process do

  import HELF.Flow

  alias Helix.Event
  alias Helix.Process.Action.Process, as: ProcessAction
  alias Helix.Process.Model.Process

  @spec signal(Process.t, Process.signal, Process.signal_params) ::
    {:ok, Process.t}
  @doc """
  Sends `signal` to the `process`.

  Emits ProcessSignaledEvent and any other event defined at the Processable
  callback.
  """
  def signal(process = %Process{}, signal, params \\ %{}) do
    flowing do
      with {:ok, events} <- ProcessAction.signal(process, signal, params) do
        Event.emit(events)

        {:ok, process}
      end
    end
  end
end
