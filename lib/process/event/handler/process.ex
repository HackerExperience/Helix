defmodule Helix.Process.Event.Handler.Process do

  alias Helix.Event
  alias Helix.Process.Action.Process, as: ProcessAction
  alias Helix.Process.Model.Process
  alias Helix.Process.Model.Processable

  alias Helix.Process.Event.Process.Signaled, as: ProcessSignaledEvent

  @doc """
  TOP-level handler for performing actions after a process has received a signal

  After a signal is sent, it will return an action defined at the corresponding
  `Processable` callback. This action is handled and executed here. Well,
  actually at `action_handler/3`.
  """
  def signal_handler(event = %ProcessSignaledEvent{}) do
    event.action
    |> action_handler(event.process, event.params)
    |> Enum.map(&(Event.set_process_id(&1, event.process.process_id)))
    |> Event.emit(from: event)
  end

  # Actions

  @spec action_handler(Processable.action, Process.t, Process.signal_params) ::
    [Event.t]
  defp action_handler(:delete, process, %{reason: reason}) do
    {:ok, events} = ProcessAction.delete(process, reason)

    events
  end

  defp action_handler({:retarget, changes}, process, _) do
    {:ok, events} = ProcessAction.retarget(process, changes)

    events
  end

  # Signals

  defp action_handler({:SIGKILL, reason}, process, _) do
    {:ok, events} = ProcessAction.signal(process, :SIGKILL, %{reason: reason})

    events
  end

  defp action_handler(:SIGRETARGET, process, _) do
    {:ok, events} = ProcessAction.signal(process, :SIGRETARGET)

    events
  end

  defp action_handler(:noop, _, _),
    do: []

  # defp action_handler(:pause, process, _) do
  #   {:ok, events} = ProcessAction.pause(process)

  #   events
  # end
end
