defmodule HELM.Entity.App do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(HELM.Entity.Repo, []),
      worker(HELM.Entity.Service, [])]

    opts = [strategy: :one_for_one, name: HELM.Entity.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
