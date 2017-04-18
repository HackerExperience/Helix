defmodule Helix.Process.Service.API.Process do

  alias Helix.Event
  alias Helix.Process.Controller.Process, as: Controller
  alias Helix.Process.Model.Process
  alias Helix.Process.Repo
  alias Helix.Process.Service.Local.TOP.Manager
  alias Helix.Process.Service.Local.TOP.Server, as: TOP

  # FIXME: this is not a good interface but i am too tired to adequate it right
  #   now
  @spec create(map) ::
    {:ok, Process.t}
    | {:error, Ecto.Changeset.t}
  def create(params) do
    with {:ok, process, events} <- Controller.create(params) do
      Event.emit(events)

      {:ok, process}
    end
  end

  @spec fetch(HELL.PK.t) ::
    Process.t
    | nil
  def fetch(id) do
    Controller.fetch(id)
  end

  @spec kill(Process.t, atom) ::
    :ok
  def kill(process, _reason) do
    process
    |> top()
    |> TOP.kill(process)
  end

  @spec get_processes_on_server(HELL.PK.t) ::
    [Process.t]
  def get_processes_on_server(gateway) do
    gateway
    |> Process.Query.from_server()
    |> Repo.all()
  end

  @spec priority(Process.t, 0..5) ::
    :ok
  def priority(process, priority) when priority in 0..5 do
    process
    |> top()
    |> TOP.priority(process, priority)
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

  defp top(process) do
    gateway = process.gateway_id

    {:ok, pid} = Manager.prepare_top(gateway)
    pid
  end
end
