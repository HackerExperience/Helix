defmodule Helix.Entity.App do

  use Application

  alias Helix.Controller.EntityService
  alias Helix.Entity.Repo

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(EntityService, []),
      worker(Repo, [])
    ]

    opts = [strategy: :one_for_one, name: Helix.Entity.Supervisor]
    Supervisor.start_link(children, opts)
  end
end