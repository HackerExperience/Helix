defmodule Helix.Event.Supervisor do

  use Supervisor

  alias Helix.Event.State.Supervisor, as: StateSupervisor

  @doc false
  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  @doc false
  def init(_) do
    children = [
      supervisor(StateSupervisor, [])
    ]

    supervise(children, strategy: :one_for_one)
  end
end
