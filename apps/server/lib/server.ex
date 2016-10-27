defmodule HELM.Server.App do
  use Application

  alias HELM.Server.Model.Repo
  alias HELM.Server.Controller.ServerService

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Repo, []),
      worker(ServerService, []),
    ]

    opts = [strategy: :one_for_one, name: HELM.Server.Supervisor]
    Supervisor.start_link(children, opts)
  end
end