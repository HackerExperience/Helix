defmodule Helix.Hardware.App do

  use Application

  alias Helix.Hardware.Repo
  alias Helix.Hardware.WS.Routes

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      worker(Repo, [])
    ]

    Routes.register_routes()

    opts = [strategy: :one_for_one, name: Helix.Hardware.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
