defmodule Helix.Hardware.Supervisor do

  use Supervisor

  alias Helix.Hardware.Repo

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  def init(_) do
    children = [
      worker(Repo, [])
    ]

    supervise(children, strategy: :one_for_one)
  end
end
