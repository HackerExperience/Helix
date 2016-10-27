defmodule HELM.Software.App do
  use Application
  
  alias HELM.Software.Repo
  alias HELM.Software.Controller.SoftwareService

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Repo, []),
      worker(SoftwareService, []),
    ]

    opts = [strategy: :one_for_one, name: HELM.Software.Supervisor]
    Supervisor.start_link(children, opts)
  end
end