defmodule Helix.Process.State.TOP.Supervisor do
  @moduledoc false

  use Supervisor

  alias Helix.Process.State.TOP.Manager, as: ManagerTOP
  alias Helix.Process.State.TOP.ChildrenSupervisor, as: ChildrenSupervisorTOP

  @spec start_link() ::
    Supervisor.on_start
  @doc false
  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @spec start_top(HELL.PK.t) ::
    Supervisor.on_start_child
  def start_top(gateway) do
    ChildrenSupervisorTOP.start_child(gateway)
  end

  @doc false
  def init(_) do
    children = [
      supervisor(ManagerTOP, []),
      supervisor(ChildrenSupervisorTOP, [])
    ]

    supervise(children, strategy: :rest_for_one)
  end
end

defmodule Helix.Process.State.TOP.ChildrenSupervisor do
  @moduledoc false

  use Supervisor

  alias Helix.Process.State.TOP.Server, as: ServerTOP

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
      worker(ServerTOP, [], restart: :transient)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end
