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
end
