defmodule Helix.Application do

  use Application

  import Supervisor.Spec

  def start(_type, _args) do
    children = [
      # worker(HELF.Broker, []),
      supervisor(Helix.Endpoint, []),
      supervisor(Helix.Application.DomainsSupervisor, [])
    ]

    opts = [strategy: :one_for_one, name: Helix.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

defmodule Helix.Application.DomainsSupervisor do

  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  def init(_) do
    children = [
      supervisor(Helix.Account.Supervisor, []),
      supervisor(Helix.Entity.Supervisor, []),
      supervisor(Helix.Hardware.Supervisor, []),
      supervisor(Helix.Log.Supervisor, []),
      supervisor(Helix.Network.Supervisor, []),
      supervisor(Helix.NPC.Supervisor, []),
      supervisor(Helix.Process.Supervisor, []),
      supervisor(Helix.Server.Supervisor, []),
      supervisor(Helix.Software.Supervisor, [])
    ]

    supervise(children, strategy: :one_for_one)
  end
end
