defmodule Helix.Process.Internal.Process do

  alias Helix.Network.Model.Connection
  alias Helix.Server.Model.Server
  alias Helix.Process.Model.Process
  alias Helix.Process.Repo

  @spec fetch(Process.id) ::
    Process.t
    | nil
  def fetch(process_id) do
    with process = %Process{} <- Repo.get(Process, process_id) do
      Process.format(process)
    end
  end

  @spec get_running_processes_of_type_on_server(Server.idt, String.t) ::
    [Process.t]
  def get_running_processes_of_type_on_server(gateway_id, type) do
    gateway_id
    |> Process.Query.by_gateway()
    |> Process.Query.by_type(type)
    |> Process.Query.by_state(:running)
    |> Repo.all()
    |> Enum.map(&Process.format/1)
  end

  @spec get_processes_on_server(Server.idt) ::
    [Process.t]
  def get_processes_on_server(gateway_id) do
    gateway_id
    |> Process.Query.by_gateway()
    |> Repo.all()
    |> Enum.map(&Process.format/1)
  end

  @spec get_processes_targeting_server(Server.idt) ::
    [Process.t]
  def get_processes_targeting_server(gateway_id) do
    gateway_id
    |> Process.Query.by_target()
    |> Process.Query.not_targeting_gateway()
    |> Repo.all()
    |> Enum.map(&Process.format/1)
  end

  @spec get_processes_of_type_targeting_server(Server.idt, String.t) ::
    [Process.t]
  def get_processes_of_type_targeting_server(gateway_id, type) do
    gateway_id
    |> Process.Query.by_target()
    |> Process.Query.not_targeting_gateway()
    |> Process.Query.by_type(type)
    |> Repo.all()
    |> Enum.map(&Process.format/1)
  end

  @spec get_processes_on_connection(Connection.idt) ::
    [Process.t]
  def get_processes_on_connection(connection_id) do
    connection_id
    |> Process.Query.by_connection()
    |> Repo.all()
    |> Enum.map(&Process.format/1)
  end

  @spec delete(Process.t) ::
    :ok
  def delete(process) do
    Repo.delete(process)

    :ok
  end
end
