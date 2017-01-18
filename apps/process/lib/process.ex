defmodule Helix.Process.App do

  use Application

  alias Helix.Process.Repo
  alias Helix.Process.Controller.ProcessService

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      worker(Repo, []),
      worker(ProcessService, []),
    ]

    opts = [strategy: :one_for_one, name: Helix.Process.Supervisor]
    Supervisor.start_link(children, opts)
  end
end