defmodule HELM.Account.App do

  use Application

  alias HELM.Account.Controller.AccountService
  alias Helix.Account.Controller.EntityObserver
  alias HELM.Account.Repo

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(AccountService, []),
      worker(EntityObserver, []),
      worker(Repo, [])
    ]

    opts = [strategy: :one_for_one, name: Account.Supervisor]
    Supervisor.start_link(children, opts)
  end
end