defmodule Helix.Process.Service.Local.Top.Supervisor do

  use Supervisor

  alias Helix.Process.Service.Local.Top.Manager
  alias Helix.Process.Service.Local.Top.ChildrenSupervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    children = [
      worker(Manager, []),
      supervisor(ChildrenSupervisor, [])
    ]

    supervise(children, strategy: :rest_for_one)
  end

  def start_top(gateway) do
    ChildrenSupervisor.start_child(gateway)
  end
end

defmodule Helix.Process.Service.Local.Top.ChildrenSupervisor do

  use Supervisor

  alias Helix.Process.Controller.TableOfProcesses

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    children = [
      worker(TableOfProcesses, [], restart: :transient)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

  def start_child(gateway) do
    Supervisor.start_child(__MODULE__, [gateway])
  end
end
