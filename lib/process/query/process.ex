defmodule Helix.Process.Query.Process do

  alias Helix.Network.Model.Connection
  alias Helix.Server.Model.Server
  alias Helix.Process.Model.Process
  alias Helix.Process.Internal.Process, as: ProcessInternal

  @spec fetch(Process.id) ::
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
    to: ProcessInternal

  @spec get_running_processes_of_type_on_server(Server.idt, String.t) ::
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
  defdelegate get_running_processes_of_type_on_server(gateway_id, type),
    to: ProcessInternal

  @spec get_processes_on_server(Server.idt) ::
    [Process.t]
  @doc """
  Fetches processes running on `gateway`

  ### Examples

      iex> get_processes_on_server("aa::bb")
      [%Process{}, %Process{}, %Process{}, %Process{}, %Process{}]
  """
  defdelegate get_processes_on_server(gateway_id),
    to: ProcessInternal

  @spec get_processes_targeting_server(Server.idt) ::
    [Process.t]
  @doc """
  Fetches remote processes affecting `gateway`

  Note that this will **not** include processes running on `gateway` even if
  they affect it

  ### Examples

      iex> get_processes_targeting_server("aa::bb")
      [%Process{}]
  """
  defdelegate get_processes_targeting_server(gateway_id),
    to: ProcessInternal

  @spec get_processes_of_type_targeting_server(Server.idt, String.t) ::
    [Process.t]
  @doc """
  Fetches remote processes of type `type` affecting `gateway`

  Note that this will **not** include processes running on `gateway` even if
  they affect it

  ### Examples

      iex> get_processes_of_type_targeting_server("aa::bb", "cracker")
      [%Process{}, %Process{}]
  """
  defdelegate get_processes_of_type_targeting_server(gateway_id, type),
    to: ProcessInternal

  @spec get_processes_on_connection(Connection.idt) ::
    [Process.t]
  @doc """
  Fetches processes using `connection`

  ### Examples

      iex> get_processes_on_connection("f::f")
      [%Process{}]
  """
  defdelegate get_processes_on_connection(connection),
    to: ProcessInternal

  @spec get_custom(Process.type, Server.idt, meta :: map) ::
    [Process.t]
    | nil
  @doc """
  Specify custom type of processes to be returned. Useful to check whether a
  process of type `type` with data matching `meta` exists on the `server_id`.
  """
  def get_custom(type, server_id, meta)

  def get_custom(type = "file_download", server_id, %{file_id: file_id}) do
    server_id
    |> get_running_processes_of_type_on_server(type)
    |> Enum.filter(&(&1.file_id == file_id))
    |> nilify_if_empty()
  end

  def get_custom(type = "file_upload", server_id, %{file_id: file_id}) do
    server_id
    |> get_running_processes_of_type_on_server(type)
    |> Enum.filter(&(&1.file_id == file_id))
    |> nilify_if_empty()
  end

  def get_custom(_, _, _),
    do: nil

  @spec nilify_if_empty([Process.t]) ::
    [Process.t]
    | nil
  defp nilify_if_empty([]),
    do: nil
  defp nilify_if_empty(list),
    do: list
end
