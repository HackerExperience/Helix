defmodule Helix.Process.Service.Local.TOP.Supervisor do
  @moduledoc false

  use Supervisor

  alias Helix.Process.Service.Local.TOP.Manager
  alias Helix.Process.Service.Local.TOP.ChildrenSupervisor

  @spec start_link() ::
    Supervisor.on_start
  @doc false
  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @spec start_top(HELL.PK.t) ::
    Supervisor.on_start_child
  def start_top(gateway) do
    ChildrenSupervisor.start_child(gateway)
  end

  @doc false
  def init(_) do
    children = [
      supervisor(Manager, []),
      supervisor(ChildrenSupervisor, [])
    ]

    supervise(children, strategy: :rest_for_one)
  end
end

defmodule Helix.Process.Service.Local.TOP.ChildrenSupervisor do
  @moduledoc false

  use Supervisor

  alias Helix.Process.Controller.TableOfProcesses

  @spec start_link() ::
    Supervisor.on_start
  @doc false
  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @spec start_child(HELL.PK.t) ::
    Supervisor.on_start_child
  def start_child(gateway) do
    Supervisor.start_child(__MODULE__, [gateway])
  end

  @doc false
  def init(_) do
    children = [
      worker(TableOfProcesses, [], restart: :transient)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end
