defmodule Helix.Process.Supervisor do

  use Supervisor

  alias Helix.Process.Repo
  alias Helix.Process.Service.Local.Top.Supervisor, as: TOP

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  def init(_) do
    children = [
      worker(Repo, []),
      supervisor(TOP, [])
    ]

    supervise(children, strategy: :rest_for_one)
  end
end
