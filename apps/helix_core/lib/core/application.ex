defmodule Helix.Core.Application do
  use Application

  @port Application.get_env(:helix_core, :router_port)

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(HELF.Broker, []),
      worker(HELF.Router, [@port])
    ]

    opts = [strategy: :one_for_one, name: Helix.Core.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
