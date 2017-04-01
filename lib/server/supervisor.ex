defmodule Helix.Server.Supervisor do

  use Supervisor

  alias Helix.Server.Repo
  alias Helix.Server.WS.Routes

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  def init(_) do
    children = [
      worker(Repo, [])
    ]

    Routes.register_routes()

    supervise(children, strategy: :one_for_one)
  end
end
