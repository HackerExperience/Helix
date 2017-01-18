defmodule Helix.Software.App do

  use Application

  alias Helix.Software.Controller.SoftwareService
  alias Helix.Software.Repo

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      worker(Repo, []),
      worker(SoftwareService, [])
    ]

    opts = [strategy: :one_for_one, name: Helix.Software.Supervisor]
    Supervisor.start_link(children, opts)
  end
end