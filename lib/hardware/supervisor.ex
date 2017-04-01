defmodule Helix.Hardware.Supervisor do

  use Supervisor

  alias Helix.Hardware.Repo
  alias Helix.Hardware.WS.Routes

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
