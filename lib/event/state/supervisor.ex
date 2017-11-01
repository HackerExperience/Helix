defmodule Helix.Event.State.Supervisor do

  use Supervisor

  alias Helix.Event.State.Timer, as: EventTimer

  @doc false
  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  @doc false
  def init(_) do
    children = [
      worker(EventTimer, [])
    ]

    supervise(children, strategy: :one_for_one)
  end
end
