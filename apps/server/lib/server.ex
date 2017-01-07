defmodule Helix.Server.App do

  use Application

  alias Helix.Server.Repo
  alias Helix.Server.Controller.ServerService

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Repo, []),
      worker(ServerService, [])
    ]

    opts = [strategy: :one_for_one, name: Helix.Server.Supervisor]
    Supervisor.start_link(children, opts)
  end
end