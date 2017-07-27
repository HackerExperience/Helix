defmodule Helix.Process.Internal.Process do

  alias Helix.Process.Model.Process
  alias Helix.Process.Repo

  @spec fetch(Process.id) ::
    Process.t
    | nil
  def fetch(process_id),
    do: Repo.get(Process, process_id)

  @spec get_running_processes_of_type_on_server(Server.t | Server.id, String.t) ::
    [Process.t]
  def get_running_processes_of_type_on_server(gateway_id, type) do
    gateway_id
    |> Process.Query.from_server()
    |> Process.Query.by_type(type)
    |> Process.Query.by_state(:running)
    |> Repo.all()
    |> Enum.map(&Process.load_virtual_data/1)
  end

  @spec get_processes_on_server(Server.t | Server.id) ::
    [Process.t]
  def get_processes_on_server(gateway_id) do
    gateway_id
    |> Process.Query.from_server()
    |> Repo.all()
    |> Enum.map(&Process.load_virtual_data/1)
  end

  @spec get_processes_targeting_server(Server.t | Server.id) ::
    [Process.t]
  def get_processes_targeting_server(gateway_id) do
    gateway_id
    |> Process.Query.by_target()
    |> Process.Query.not_targeting_gateway()
    |> Repo.all()
    |> Enum.map(&Process.load_virtual_data/1)
  end

  @spec get_processes_of_type_targeting_server(Server.t | Server.id, String.t) ::
    [Process.t]
  def get_processes_of_type_targeting_server(gateway_id, type) do
    gateway_id
    |> Process.Query.by_target()
    |> Process.Query.not_targeting_gateway()
    |> Process.Query.by_type(type)
    |> Repo.all()
    |> Enum.map(&Process.load_virtual_data/1)
  end

  @spec get_processes_on_connection(Connection.t | Connection.id) ::
    [Process.t]
  def get_processes_on_connection(connection_id) do
    connection_id
    |> Process.Query.by_connection()
    |> Repo.all()
    |> Enum.map(&Process.load_virtual_data/1)
  end

  @spec delete(Process.t | Process.id) ::
    :ok
  def delete(process) do
    process
    |> Process.Query.by_process()
    |> Repo.delete_all()

    :ok
  end
end
