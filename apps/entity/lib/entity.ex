defmodule HELM.Entity.App do
  use Application

  alias HELM.Controller.EntityService, as: EntityService
  alias HELM.Entity.Model.Repo, as: Repo

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(EntityService, []),
      worker(Repo, [])]

    opts = [strategy: :one_for_one, name: HELM.Entity.Supervisor]
    Supervisor.start_link(children, opts)
  end
end