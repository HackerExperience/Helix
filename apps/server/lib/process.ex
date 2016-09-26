defmodule HELM.Server.App do
  use Application

  alias HELM.Server

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Server.Repo, []),
      worker(Server.Service, []),
    ]

    opts = [strategy: :one_for_one, name: HELM.Server.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
