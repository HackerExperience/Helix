defmodule Helix.Server.Supervisor do

  use Supervisor

  alias Helix.Server.Repo
  alias Helix.Server.State.Supervisor, as: SupervisorState

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  def init(_) do
    children = [
      supervisor(Repo, []),
      supervisor(SupervisorState, [])
    ]

    supervise(children, strategy: :rest_for_one)
  end
end
