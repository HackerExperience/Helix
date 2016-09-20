defmodule HELM.Entity.App do
  use Application

  alias HELM.Entity
  alias HELF.Broker

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Entity.Repo, []),
      worker(Entity.Service, [])
    ]

    opts = [strategy: :one_for_one, name: Entity.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
