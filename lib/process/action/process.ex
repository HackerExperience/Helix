defmodule Helix.Process.Action.Process do

  import HELL.Macros

  alias Helix.Event
  alias Helix.Network.Model.Network
  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Process.Internal.Process, as: ProcessInternal
  alias Helix.Process.Model.Process
  alias Helix.Process.Model.Processable

  alias Helix.Process.Event.Process.Completed, as: ProcessCompletedEvent
  alias Helix.Process.Event.Process.Created, as: ProcessCreatedEvent
  alias Helix.Process.Event.Process.Killed, as: ProcessKilledEvent
  alias Helix.Process.Event.Process.Signaled, as: ProcessSignaledEvent

  @spec create(Process.creation_params) ::
    {:ok, Process.t, [ProcessCreatedEvent.t]}
    | {:error, Process.changeset}
  @doc """
  Creates a process.

  This function is optimistic; the server may not have enough resources to
  allocate the process, in which case eventually a `ProcessCreateFailedEvent`
  will be emitted - but that's not our problem. We only create a process and
  let the world know about it.
  """
  def create(params) do
    with {:ok, process} <- ProcessInternal.create(params) do
      {gateway_ip, target_ip} = get_process_ips(params)

      event =
        ProcessCreatedEvent.new(
          process, gateway_ip, target_ip, confirmed: false
        )

      {:ok, process, [event]}
    end
  end

  @spec delete(Process.t, Process.kill_reason) ::
    {:ok, [ProcessCompletedEvent.t | ProcessKilledEvent.t]}
  @doc """
  Deletes a process.

  If the `reason` for deletion is `:completed`, it means the Process received a
  SIGTERM and has reach its objective, so a `ProcessCompletedEvent` shall be
  returned. Otherwise, a `ProcessKilledEvent` is returned.
  """
  def delete(process = %Process{}, reason) do
    ProcessInternal.delete(process)

    event =
      if reason == :completed do
        ProcessCompletedEvent.new(process)
      else
        ProcessKilledEvent.new(process, reason)
      end

    {:ok, [event]}
  end

  @spec retarget(Process.t, Process.retarget_changes) ::
    {:ok, list}
  @doc """
  Retargets a process.

  Modifies the process target and/or objectives according to `changes`.
  """
  def retarget(process = %Process{}, changes) do
    ProcessInternal.retarget(process, changes)

    {:ok, []}
  end

  # def pause(process = %Process{}) do
  #   ProcessInternal.pause(process)

  #   event = ProcessPausedEvent.new(process)

  #   {:ok, [event]}
  # end

  @spec signal(Process.t, Process.signal, Process.signal_params) ::
    {:ok, [Event.t]}
  @doc """
  Delivers the given `signal` to the Processable implemented by `process.data`.

  After delivering the signal, other than accumulating the events defined at the
  Processable implementation, also accumulates a `ProcessSignaledEvent`.
  """
  def signal(process = %Process{}, signal, params \\ %{}) do
    {action, events} = signal_handler(signal, process, params)

    signaled_event = ProcessSignaledEvent.new(signal, process, action, params)

    {:ok, events ++ [signaled_event]}
  end

  @spec signal_handler(Process.signal, Process.t, Process.signal_params) ::
    {Processable.action, [Event.t]}
  docp """
  Actually calls the corresponding signal callback, relaying the required info.
  """
  defp signal_handler(:SIGTERM, process, _),
    do: Processable.complete(process.data, process)

  defp signal_handler(:SIGKILL, process, %{reason: reason}),
    do: Processable.kill(process.data, process, reason)

  # defp signal_handler(:SIGSTOP, process, _),
  #   do: Processable.stop(process.data, process)

  # defp signal_handler(:SIGCONT, process, _),
  #   do: Processable.resume(process.data, process, reason)

  # defp signal_handler(:SIGPRIO, process, %{priority: priority}),
  #   do: Processable.priority(process.data, process, priority)

  defp signal_handler(:SIGRETARGET, process, _),
    do: Processable.retarget(process.data, process)

  defp signal_handler(:SIGSRCCONND, process, %{connection: connection}),
    do: Processable.source_connection_closed(process.data, process, connection)

  defp signal_handler(:SIGTGTCONND, process, %{connection: connection}),
    do: Processable.target_connection_closed(process.data, process, connection)

  # defp signal_handler(:SIGSRCFILED, process, %{file: file}),
  #   do: Processable.file_deleted(process.data, process, file)

  @spec get_process_ips(Process.creation_params) ::
    {gateway_ip :: Network.ip, target_ip :: Network.ip}
    | {nil, nil}
  docp """
  I haz get process ips, which shall be used by ProcessCreatedEvent.
  """
  defp get_process_ips(%{network_id: nil}),
    do: {nil, nil}
  defp get_process_ips(params) do
    gateway_ip = ServerQuery.get_ip(params.gateway_id, params.network_id)

    target_ip =
      if params.gateway_id == params.target_id do
        gateway_ip
      else
        ServerQuery.get_ip(params.target_id, params.network_id)
      end

    {gateway_ip, target_ip}
  end
end
