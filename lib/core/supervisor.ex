defmodule Helix.Core.Supervisor do

  use Supervisor

  alias Helix.Core.Repo

  @doc false
  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  @doc false
  def init(_) do
    children = [
      worker(Repo, [])
    ]

    supervise(children, strategy: :one_for_one)
  end
end
