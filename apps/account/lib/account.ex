defmodule HELM.Account.App do

  use Application

  alias HELM.Account.Controller.AccountService
  alias HELM.Account.Repo

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(AccountService, []),
      worker(Repo, [])
    ]

    opts = [strategy: :one_for_one, name: Account.Supervisor]
    Supervisor.start_link(children, opts)
  end
end