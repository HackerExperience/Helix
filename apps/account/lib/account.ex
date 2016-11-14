defmodule HELM.Account.App do
  use Application

  alias HELM.Account.Controller.AccountService
  alias HELM.Account.Repo

  @spec start(_type :: Application.start_type, _args :: []) :: {:ok, pid} | {:error, term}
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