defmodule Helix.Process.Action.Process do

  import HELL.Macros

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
  alias Helix.Process.Query.Process, as: ProcessQuery
  alias Helix.Process.State.TOP.Manager, as: ManagerTOP
  alias Helix.Process.State.TOP.Server, as: ServerTOP

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
      :gateway_id => Server.idtb,
      :target_id => Server.idtb,
      :data => Processable.t,
      :type => String.t,
      optional(:file_id) => File.idtb | nil,
      optional(:network_id) => Network.idtb | nil,
      optional(:connection_id) => Connection.idtb | nil,
      optional(:objective) => map
    } | term

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

  def delete(process = %Process{}) do
    ProcessInternal.delete(process)
  end

  def signal(process = %Process{}, signal, params \\ %{}) do
    {action, events} =
      case signal do
        :SIGKILL ->
          Processable.kill(process.data, process, params.reason)
      end

    signaled_event = ProcessSignaledEvent.new(signal, process, action)

    {:ok, events ++ [signaled_event]}
  end

  @spec pause(Process.t) ::
    :ok
  @doc """
  Changes a process state to _paused_

  This will cause it not to "process" the allocated resources and thus suspend
  it's effect.

  Some processes might still consume resources (without any progress) on paused
  state

  This function is idempotent

  ### Examples

      iex> pause(%Process{})
      :ok
  """
  def pause(process) do
  end

  @spec resume(Process.t) ::
    :ok
  @doc """
  Changes a process state from _paused_ to _running_

  This will allow the process to continue processing resources and causing side-
  effects

  This function is idempotent

  ### Examples

      iex> resume(%Process{})
      :ok
  """
  def resume(process) do
  end

  @spec priority(Process.t, 0..5) ::
    :ok
  @doc """
  Changes the priority of a process

  Effectively this will change how much proportionally the input process will
  receive of dynamic resources. The higher the priority, the higher the amount
  of dynamic resources a process will receive

  ### Examples

      iex> priority(%Process{}, 1)
      :ok

      iex> priority(%Process{}, 5)
      :ok
  """
  def priority(process, priority) when priority in 0..5 do
  end

  @spec kill(Process.t, atom) ::
    :ok
  @doc """
  Stops a process with reason `reason`

  ### Examples

      iex> kill(%Process{}, :normal)
      :ok
  """
  def kill(process, _reason) do
  end

  @doc false
  def reset_processes_on_server(gateway_id) do
    case ManagerTOP.get(gateway_id) do
      nil ->
        :noop
      pid ->
        processes = ProcessQuery.get_processes_on_server(gateway_id)
        ServerTOP.reset_processes(pid, processes)
    end
  end

  @spec prepare_create_params(base_params, Entity.id) ::
    Process.create_params
  defp prepare_create_params(params, source_entity_id),
    do: Map.put(params, :source_entity_id, source_entity_id)

  @spec get_process_entities(base_params) ::
    {source_entity :: Entity.id, target_entity :: Entity.id}
  defp get_process_entities(params) do
    source_entity = EntityQuery.fetch_by_server(params.gateway_id)

    target_entity =
      if params.gateway_id == params.target_id do
        source_entity
      else
        EntityQuery.fetch_by_server(params.target_id)
      end

    {source_entity.entity_id, target_entity.entity_id}
  end

  @spec get_process_ips(base_params) ::
    {gateway_ip :: Network.ip, target_ip :: Network.ip}
    | {nil, nil}
  defp get_process_ips(params = %{network_id: _}) do
    gateway_ip = ServerQuery.get_ip(params.gateway_id, params.network_id)

    target_ip =
      if params.gateway_id == params.target_id do
        gateway_ip
      else
        ServerQuery.get_ip(params.target_id, params.network_id)
      end

    {gateway_ip, target_ip}
  end
  defp get_process_ips(_),
    do: {nil, nil}
end
