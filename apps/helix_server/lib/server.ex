defmodule Helix.Server.App do

  use Application

  alias Helix.Server.Repo
  alias Helix.Server.WS.Routes

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      worker(Repo, [])
    ]

    Routes.register_routes()

    opts = [strategy: :one_for_one, name: Helix.Server.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
