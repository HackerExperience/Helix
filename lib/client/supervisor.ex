defmodule Helix.Client.Supervisor do

  use Supervisor

  alias Helix.Client.Repo

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  def init(_) do
    children = [
      supervisor(Repo, [])
    ]

    supervise(children, strategy: :one_for_one)
  end
end
