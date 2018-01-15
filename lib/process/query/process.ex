defmodule Helix.Process.Query.Process do

  import __MODULE__.Macros

  alias Helix.Network.Model.Connection
  alias Helix.Server.Model.Server
  alias Helix.Software.Model.File
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

  @spec get_running_processes_of_type_on_server(Server.idt, Process.type) ::
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
  Fetches *all* processes running on the given server.

  Returns both local and remote processes.
  """
  defdelegate get_processes_on_server(gateway_id),
    to: ProcessInternal

  @spec get_processes_originated_on_connection(Connection.idt) ::
    [Process.t]
  @doc """
  Fetches processes that originated from `connection`

  ### Examples

      iex> get_processes_originated_on_connection("f::f")
      [%Process{}]
  """
  defdelegate get_processes_originated_on_connection(connection),
    to: ProcessInternal

  @spec get_processes_targeting_connection(Connection.idt) ::
    [Process.t]
  @doc """
  Returns a list of processes that are targeting `connection`.
  """
  defdelegate get_processes_targeting_connection(connection),
    to: ProcessInternal

  @spec get_custom(Process.type, Server.idt, meta :: map) ::
    [Process.t]
    | nil
  @doc """
  Specify custom type of processes to be returned. Useful to check whether a
  process of type `type` with data matching `meta` exists on the server.

  Its code is generated at `ProcessQuery.Macros`. It simply grabs the returned
  function and uses it to filter all processes of that type within the server.

  The generated code is something like:

  ```
  def get_custom(type = :process_type, server_id, %{file_id: file_id}) do
    server_id
    |> get_running_processes_of_type_on_server(type)
    |> Enum.fiter(&(&1.file_id == file_id))
    |> nilify_if_empty()
  end
  ```
  """
  get_custom %{src_file_id: file_id = %File.ID{}},
    do: &(&1.src_file_id == file_id)
  get_custom %{tgt_file_id: file_id = %File.ID{}},
    do: &(&1.tgt_file_id == file_id)
end
