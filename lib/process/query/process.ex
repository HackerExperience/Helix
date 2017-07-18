defmodule Helix.Process.Query.Process do

  alias Helix.Process.Model.Process
  alias Helix.Process.Query.Process.Origin, as: ProcessQueryOrigin

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
  defdelegate fetch(id),
    to: ProcessQueryOrigin

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
  defdelegate get_running_processes_of_type_on_server(gateway, type),
    to: ProcessQueryOrigin

  @spec get_processes_on_server(HELL.PK.t) ::
    [Process.t]
  @doc """
  Fetches processes running on `gateway`

  ### Examples

      iex> get_processes_on_server("aa::bb")
      [%Process{}, %Process{}, %Process{}, %Process{}, %Process{}]
  """
  defdelegate get_processes_on_server(gateway),
    to: ProcessQueryOrigin

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
  defdelegate get_processes_targeting_server(gateway),
    to: ProcessQueryOrigin

  @spec get_processes_of_type_targeting_server(HELL.PK.t, String.t) ::
    [Process.t]
  @doc """
  Fetches remote processes of type `type` affecting `gateway`

  Note that this will **not** include processes running on `gateway` even if
  they affect it

  ### Examples

      iex> get_processes_of_type_targeting_server("aa::bb", "cracker")
      [%Process{}, %Process{}]
  """
  defdelegate get_processes_of_type_targeting_server(gateway, type),
    to: ProcessQueryOrigin

  @spec get_processes_on_connection(HELL.PK.t) ::
    [Process.t]
  @doc """
  Fetches processes using `connection`

  ### Examples

      iex> get_processes_on_connection("f::f")
      [%Process{}]
  """
  defdelegate get_processes_on_connection(connection),
    to: ProcessQueryOrigin

  defmodule Origin do

    alias Helix.Process.Internal.Process, as: ProcessInternal
    alias Helix.Process.Repo

    def fetch(id) do
      ProcessInternal.fetch(id)
    end

    def get_running_processes_of_type_on_server(gateway, type) do
      gateway
      |> Process.Query.from_server()
      |> Process.Query.by_type(type)
      |> Process.Query.by_state(:running)
      |> Repo.all()
      |> Enum.map(&Process.load_virtual_data/1)
    end

    def get_processes_on_server(gateway) do
      gateway
      |> Process.Query.from_server()
      |> Repo.all()
      |> Enum.map(&Process.load_virtual_data/1)
    end

    def get_processes_targeting_server(gateway) do
      gateway
      |> Process.Query.by_target()
      |> Process.Query.not_targeting_gateway()
      |> Repo.all()
      |> Enum.map(&Process.load_virtual_data/1)
    end

    def get_processes_of_type_targeting_server(gateway, type) do
      gateway
      |> Process.Query.by_target()
      |> Process.Query.not_targeting_gateway()
      |> Process.Query.by_type(type)
      |> Repo.all()
      |> Enum.map(&Process.load_virtual_data/1)
    end

    def get_processes_on_connection(connection) do
      connection
      |> Process.Query.by_connection_id()
      |> Repo.all()
      |> Enum.map(&Process.load_virtual_data/1)
    end

  end
end
