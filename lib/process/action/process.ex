defmodule Helix.Process.Action.Process do

  alias HELL.IPv4
  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Process.Model.Process
  alias Helix.Process.Model.Process.ProcessCreatedEvent
  alias Helix.Process.Query.Process, as: ProcessQuery
  alias Helix.Process.State.TOP.Manager, as: ManagerTOP
  alias Helix.Process.State.TOP.Server, as: ServerTOP

  @type on_create ::
    {:ok, Process.t, [ProcessCreatedEvent.t]}
    | on_create_error

  @type on_create_error ::
    {:error, Ecto.Changeset.t}
    | {:error, :resources}

  @type base_params ::
    map  # TODO

  # REVIEW: Maybe receive gateway_id as a separate argument and inject it on the
  #   params map
  @spec create(base_params) ::
    on_create
  @doc """
  Creates a new process

  Each process defines its required arguments. When the process is successfully
  created, it'll cause the server to reallocate resources to properly hold it.

  Might return `{:error, :resources}` if the server does not have enough
  resources to hold its current processes along with the input process

  ### Examples

      iex> create(%{
        gateway_id: "aa::bb",
        target_server_id: "aa::bb",
        file_id: "1:2::3",
        process_data: %Firewall.ProcessType.Passive{version: 1},
        process_type: "firewall_passive"
      })
      {:ok, %Process{}, [%{}]}
  """
  def create(params) do
    # TODO: i don't like this with here as it is. I think getting the TOP pid
    #   should be more transparent
    with \
      %{gateway_id: gateway} <- params, # TODO: Return an error on unmatch
      {source_entity_id, target_entity_id} <- get_process_entities(params),
      {gateway_ip, target_ip} <- get_process_ips(params),
      process_params = prepare_create_params(params, source_entity_id),
      {:ok, pid} = ManagerTOP.prepare_top(gateway),
      {:ok, process} <- ServerTOP.create(pid, process_params)
    do
      event = %ProcessCreatedEvent{
        process: process,
        gateway_id: process.gateway_id,
        target_id: process.target_server_id,
        gateway_entity_id: source_entity_id,
        target_entity_id: target_entity_id,
        gateway_ip: gateway_ip,
        target_ip: target_ip
      }

      {:ok, process, [event]}
    end
  end

  @spec prepare_create_params(base_params, Entity.id) ::
    Process.create_params
  defp prepare_create_params(params, source_entity_id),
    do: Map.put(params, :source_entity_id, source_entity_id)

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
    process
    |> top()
    |> ServerTOP.pause(process)
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
    process
    |> top()
    |> ServerTOP.resume(process)
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
    process
    |> top()
    |> ServerTOP.priority(process, priority)
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
    process
    |> top()
    |> ServerTOP.kill(process)
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

  @spec top(Process.t) ::
    pid
  defp top(process) do
    gateway = process.gateway_id

    {:ok, pid} = ManagerTOP.prepare_top(gateway)
    pid
  end

  @spec get_process_entities(Process.create_params) ::
    {source_entity :: Entity.id, target_entity :: Entity.id}
  defp get_process_entities(params) do
    source_entity = EntityQuery.fetch_by_server(params.gateway_id)

    target_entity =
      if params.gateway_id == params.target_server_id do
        source_entity
      else
        EntityQuery.fetch_by_server(params.target_server_id)
      end

    {source_entity.entity_id, target_entity.entity_id}
  end

  # Review: Help with typespec
  @spec get_process_ips(Process.create_params) ::
    {gateway_ip :: IPv4.t, target_ip :: IPv4.t}
  defp get_process_ips(params = %{network_id: _}) do
    gateway_ip = ServerQuery.get_ip(params.gateway_id, params.network_id)

    target_ip =
      if params.gateway_id == params.target_server_id do
        gateway_ip
      else
        ServerQuery.get_ip(params.target_server_id, params.network_id)
      end

    {gateway_ip, target_ip}
  end

  @spec get_process_ips(Process.create_params) ::
    {nil, nil}
  defp get_process_ips(_),
    do: {nil, nil}
end
