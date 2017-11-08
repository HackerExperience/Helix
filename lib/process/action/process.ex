defmodule Helix.Process.Action.Process do

  alias Helix.Event
  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Network.Model.Connection
  alias Helix.Network.Model.Network
  alias Helix.Server.Model.Server
  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Software.Model.File
  alias Helix.Process.Internal.Process, as: ProcessInternal
  alias Helix.Process.Model.Process
  alias Helix.Process.Model.Processable

  alias Helix.Process.Event.Process.Completed, as: ProcessCompletedEvent
  alias Helix.Process.Event.Process.Created, as: ProcessCreatedEvent
  alias Helix.Process.Event.Process.Signaled, as: ProcessSignaledEvent

  @type on_create ::
    {:ok, Process.t, [ProcessCreatedEvent.t]}
    | on_create_error

  @type on_create_error ::
    {:error, Ecto.Changeset.t}
    | {:error, :resources}

  @type base_params ::
    %{
      :gateway_id => Server.id,
      :target_id => Server.id,
      :data => Processable.t,
      :type => Process.type,
      :file_id => File.id | nil,
      :network_id => Network.id | nil,
      :connection_id => Connection.id | nil,
      :objective => map,
      :l_dynamic => Process.dynamic,
      :r_dynamic => Process.dynamic,
      :static => Process.static
    }

  @spec create(base_params) ::
    {:ok, Process.t, [ProcessCreatedEvent.t]}
    | {:error, Process.changeset}
  def create(params) do
    with \
      source_entity = EntityQuery.fetch_by_server(params.gateway_id),
      {gateway_ip, target_ip} <- get_process_ips(params),
      process_params = prepare_create_params(params, source_entity.entity_id),
      {:ok, process} <- ProcessInternal.create(process_params)
    do
      event =
        ProcessCreatedEvent.new(
          process, gateway_ip, target_ip, confirmed: false
        )

      {:ok, process, [event]}
    end
  end

  @spec delete(Process.t, Process.kill_reason) ::
    {:ok, [ProcessCompletedEvent.t]}
  def delete(process = %Process{}, reason) do
    ProcessInternal.delete(process)

    event =
      if reason == :completed do
        ProcessCompletedEvent.new(process)
      else
        ProcessCompletedEvent.new(process)
        # ProcessKilledEvent.new(process)
      end

    {:ok, [event]}
  end

  # def pause(process = %Process{}) do
  #   ProcessInternal.pause(process)

  #   event = ProcessPausedEvent.new(process)

  #   {:ok, [event]}
  # end

  @spec signal(Process.t, Process.signal, Process.signal_params) ::
    {:ok, [Event.t]}
  def signal(process = %Process{}, signal, params \\ %{}) do
    {action, events} = signal_handler(signal, process, params)

    signaled_event = ProcessSignaledEvent.new(signal, process, action, params)

    {:ok, events ++ [signaled_event]}
  end

  @spec signal_handler(Process.signal, Process.t, Process.signal_params) ::
    {Processable.action, [Event.t]}
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

  defp signal_handler(:SIGCONND, process, %{connection: connection}),
    do: Processable.connection_closed(process.data, process, connection)

  # defp signal_handler(:SIGFILED, process, %{file: file}),
  #   do: Processable.file_deleted(process.data, process, file)

  @spec prepare_create_params(base_params, Entity.id) ::
    Process.creation_params
  defp prepare_create_params(params, source_entity_id),
    do: Map.put(params, :source_entity_id, source_entity_id)

  @spec get_process_ips(base_params) ::
    {gateway_ip :: Network.ip, target_ip :: Network.ip}
    | {nil, nil}
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
