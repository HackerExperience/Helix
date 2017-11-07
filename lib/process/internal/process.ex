defmodule Helix.Process.Internal.Process do

  alias Helix.Network.Model.Connection
  alias Helix.Server.Model.Server
  alias Helix.Process.Model.Process
  alias Helix.Process.Repo

  def create(params) do
    params
    |> Process.create_changeset()
    |> Repo.insert()
  end

  @spec fetch(Process.id) ::
    Process.t
    | nil
  def fetch(process_id) do
    with process = %Process{} <- Repo.get(Process, process_id) do
      Process.format(process)
    end
  end

  @spec get_processes_on_server(Server.idt) ::
    [Process.t]
  def get_processes_on_server(server_id) do
    server_id
    |> Process.Query.on_server()
    |> Repo.all()
    |> Enum.map(&Process.format/1)
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

  @spec get_processes_on_connection(Connection.idt) ::
    [Process.t]
  def get_processes_on_connection(connection_id) do
    connection_id
    |> Process.Query.by_connection()
    |> Repo.all()
    |> Enum.map(&Process.format/1)
  end

  def batch_update(processes) do
    # TODO: Transaction
    Enum.each(processes, fn process ->
      Repo.update(process)
    end)
  end

  @spec delete(Process.t) ::
    :ok
  @doc """
  Deletes a process.

  Using `Repo.delete_all/1` is a better idea than `Repo.delete/1`, since it may
  happen that TOP would attempt to delete so-called "stale" Repo structs.

  This happens when the side-effect of a process would lead to itself being
  deleted. Example: When completing a BankTransferProcess, the underlying
  connection will be closed. But when a ConnectionClosedEvent is emitted, any
  underlying Process with such connection would also be closed. This race
  condition is "harmless" in our context.
  """
  def delete(process) do
    process.process_id
    |> Process.Query.by_id()
    |> Repo.delete_all()

    :ok
  end
end
