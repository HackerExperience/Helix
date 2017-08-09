defmodule Helix.Process.Action.Process do

  alias Helix.Event
  alias Helix.Process.Query.Process, as: ProcessQuery
  alias Helix.Process.Model.Process
  alias Helix.Process.Model.Process.ProcessCreatedEvent
  alias Helix.Process.State.TOP.Manager, as: ManagerTOP
  alias Helix.Process.State.TOP.Server, as: ServerTOP

  @type on_create ::
    {:ok, Process.t}
    | {:error, Ecto.Changeset.t}
    | {:error, :resources}

  # REVIEW: Maybe receive gateway_id as a separate argument and inject it on the
  #   params map
  @spec create(Process.create_params) ::
    on_create
  @doc """
  Creates a new process

  Each process defines it's required arguments. When the process is successfully
  created, it'll cause the server to reallocate resources to properly hold it.

  Might return `{:error, :resources}` if the server does not have enough
  resources to hold it's current processes along with the input process

  ### Examples

      iex> create(%{
        gateway_id: "aa::bb",
        target_server_id: "aa::bb",
        file_id: "1:2::3",
        process_data: %Firewall.ProcessType.Passive{version: 1},
        process_type: "firewall_passive"
      })
      {:ok, %Process{}}
  """
  def create(params) do
    # TODO: i don't like this with here as it is. I think getting the TOP pid
    #   should be more transparent
    with \
      %{gateway_id: gateway} <- params, # TODO: Return an error on unmatch
      {:ok, pid} = ManagerTOP.prepare_top(gateway),
      {:ok, process} <- ServerTOP.create(pid, params)
    do
      # Event definition doesn't belongs here
      event = %ProcessCreatedEvent{
        process_id: process.process_id,
        gateway_id: process.gateway_id,
        target_id: process.target_server_id
      }

      Event.emit(event)

      {:ok, process}
    end
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
end
