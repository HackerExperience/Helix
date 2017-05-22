defmodule Helix.Process.Service.API.Process do

  alias Helix.Event
  alias Helix.Process.Controller.Process, as: Controller
  alias Helix.Process.Model.Process
  alias Helix.Process.Repo
  alias Helix.Process.Model.Process.ProcessCreatedEvent
  alias Helix.Process.Service.Local.TOP.Manager
  alias Helix.Process.Service.Local.TOP.Server, as: TOP

  @spec create(Process.create_params) ::
    {:ok, Process.t}
    | {:error, Ecto.Changeset.t}
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
  def fetch(id) do
    Controller.fetch(id)
  end

  @spec get_processes_on_server(HELL.PK.t) ::
    [Process.t]
  def get_processes_on_server(gateway) do
    gateway
    |> Process.Query.from_server()
    |> Repo.all()
    |> Enum.map(&Process.load_virtual_data/1)
  end

  @spec get_processes_targeting_server(HELL.PK.t) ::
    [Process.t]
  def get_processes_targeting_server(gateway) do
    gateway
    |> Process.Query.by_target()
    |> Repo.all()
    |> Enum.map(&Process.load_virtual_data/1)
  end

  @spec get_processes_on_connection(HELL.PK.t) ::
    [Process.t]
  def get_processes_on_connection(connection_id) do
    connection_id
    |> Process.Query.by_connection_id()
    |> Repo.all()
    |> Enum.map(&Process.load_virtual_data/1)
  end

  @spec pause(Process.t) ::
    :ok
  def pause(process) do
    process
    |> top()
    |> TOP.pause(process)
  end

  @spec resume(Process.t) ::
    :ok
  def resume(process) do
    process
    |> top()
    |> TOP.resume(process)
  end

  @spec priority(Process.t, 0..5) ::
    :ok
  def priority(process, priority) when priority in 0..5 do
    process
    |> top()
    |> TOP.priority(process, priority)
  end

  @spec kill(Process.t, atom) ::
    :ok
  def kill(process, _reason) do
    process
    |> top()
    |> TOP.kill(process)
  end

  defp top(process) do
    gateway = process.gateway_id

    {:ok, pid} = Manager.prepare_top(gateway)
    pid
  end
end
