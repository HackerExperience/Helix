defmodule Helix.Cache.Supervisor do

  use Supervisor

  alias Helix.Cache.Repo
  alias Helix.Cache.State.Supervisor, as: SupervisorState

  @doc false
  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  @doc false
  def init(_) do
    children = [
      worker(Repo, []),
      supervisor(SupervisorState, [])
    ]

    supervise(children, strategy: :rest_for_one)
  end
end
