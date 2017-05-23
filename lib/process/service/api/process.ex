defmodule Helix.Process.Service.API.Process do

  alias Helix.Event
  alias Helix.Process.Controller.Process, as: Controller
  alias Helix.Process.Model.Process
  alias Helix.Process.Repo
  alias Helix.Process.Model.Process.ProcessCreatedEvent
  alias Helix.Process.Service.Local.TOP.Manager
  alias Helix.Process.Service.Local.TOP.Server, as: TOP

  # REVIEW: Maybe receive gateway_id as a separate argument and inject it on the
  #   params map
  @spec create(Process.create_params) ::
    {:ok, Process.t}
    | {:error, Ecto.Changeset.t}
    | {:error, :resources}
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
      {:ok, pid} = Manager.prepare_top(gateway),
      {:ok, process} <- TOP.create(pid, params)
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

  @spec fetch(HELL.PK.t) ::
    Process.t
    | nil
  @doc """
  Fetches a process

  ### Examples

      iex> fetch("a:b:c::d")
      %Process{}

      iex> fetch("::")
      nil
  """
  def fetch(id) do
    Controller.fetch(id)
  end

  @spec get_running_processes_of_type_on_server(HELL.PK.t, String.t) ::
    [Process.t]
  @doc """
  Fetches processes running on `gateway` that are of `type`

  ### Examples

      iex> get_running_processes_of_type_on_server("aa::bb", "firewall_passive")
      [%Process{process_type: "firewall_passive"}]

      iex> get_running_processes_of_type_on_server("aa::bb", "cracker")
      []

      iex> get_running_processes_of_type_on_server("aa::bb", "file_download")
      [%Process{}, %Process{}, %Process{}]
  """
  def get_running_processes_of_type_on_server(gateway, type) do
    gateway
    |> Process.Query.from_server()
    |> Process.Query.by_type(type)
    |> Process.Query.by_state(:running)
    |> Repo.all()
    |> Enum.map(&Process.load_virtual_data/1)
  end

  @spec get_processes_on_server(HELL.PK.t) ::
    [Process.t]
  @doc """
  Fetches processes running on `gateway`

  ### Examples

      iex> get_processes_on_server("aa::bb")
      [%Process{}, %Process{}, %Process{}, %Process{}, %Process{}]
  """
  def get_processes_on_server(gateway) do
    gateway
    |> Process.Query.from_server()
    |> Repo.all()
    |> Enum.map(&Process.load_virtual_data/1)
  end

  @spec get_processes_targeting_server(HELL.PK.t) ::
    [Process.t]
  @doc """
  Fetches remote processes affecting `gateway`

  Note that this will **not** include processes running on `gateway` even if
  they affect it

  ### Examples

      iex> get_processes_targeting_server("aa::bb")
      [%Process{}]
  """
  def get_processes_targeting_server(gateway) do
    gateway
    |> Process.Query.by_target()
    |> Process.Query.not_targeting_gateway()
    |> Repo.all()
    |> Enum.map(&Process.load_virtual_data/1)
  end

  @spec get_processes_on_connection(HELL.PK.t) ::
    [Process.t]
  @doc """
  Fetches processes using `connection`

  ### Examples

      iex> get_processes_on_connection("f::f")
      [%Process{}]
  """
  def get_processes_on_connection(connection) do
    connection
    |> Process.Query.by_connection_id()
    |> Repo.all()
    |> Enum.map(&Process.load_virtual_data/1)
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
    |> TOP.pause(process)
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
    |> TOP.resume(process)
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
    |> TOP.priority(process, priority)
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
    |> TOP.kill(process)
  end

  @spec top(Process.t) ::
    pid
  defp top(process) do
    gateway = process.gateway_id

    {:ok, pid} = Manager.prepare_top(gateway)
    pid
  end
end
