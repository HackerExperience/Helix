defmodule Helix.Log.Supervisor do
  @moduledoc false

  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  def init(_) do
    children = [
      worker(Helix.Log.Repo, [])
    ]

    supervise(children, strategy: :one_for_one)
  end
end
