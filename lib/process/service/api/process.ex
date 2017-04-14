defmodule Helix.Process.Service.API.Process do

  alias Helix.Event
  alias Helix.Process.Controller.Process, as: Controller
  alias Helix.Process.Controller.TableOfProcesses
  alias Helix.Process.Model.Process
  alias Helix.Process.Repo
  alias Helix.Process.Service.Local.TOP.Manager

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
    pid = top(process)

    TableOfProcesses.kill(pid, process.process_id)
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
    pid = top(process)

    TableOfProcesses.priority(pid, process.process_id, priority)
  end

  @spec pause(Process.t) ::
    :ok
  def pause(process) do
    pid = top(process)

    TableOfProcesses.pause(pid, process.process_id)
  end

  @spec resume(Process.t) ::
    :ok
  def resume(process) do
    pid = top(process)

    TableOfProcesses.resume(pid, process.process_id)
  end

  defp top(process) do
    gateway = process.gateway_id

    {:ok, pid} = Manager.prepare_top(gateway)
    pid
  end
end
