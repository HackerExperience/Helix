defmodule Helix.Process.State.TOP.Supervisor do
  @moduledoc false

  use Supervisor

  alias Helix.Server.Model.Server
  alias Helix.Process.State.TOP.Manager, as: TOPManager
  alias Helix.Process.State.TOP.ChildrenSupervisor, as: TOPChildrenSupervisor

  @spec start_link() ::
    Supervisor.on_start
  @doc false
  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @spec start_top(Server.id) ::
    Supervisor.on_start_child
  def start_top(gateway) do
    TOPChildrenSupervisor.start_child(gateway)
  end

  @doc false
  def init(_) do
    children = [
      supervisor(TOPManager, []),
      supervisor(TOPChildrenSupervisor, [])
    ]

    supervise(children, strategy: :rest_for_one)
  end
end

defmodule Helix.Process.State.TOP.ChildrenSupervisor do
  @moduledoc false

  use Supervisor

  alias Helix.Server.Model.Server
  alias Helix.Process.State.TOP.Server, as: ServerTOP

  @spec start_link() ::
    Supervisor.on_start
  @doc false
  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @spec start_child(Server.id) ::
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
