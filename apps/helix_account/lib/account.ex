defmodule Helix.Account.App do

  use Application

  alias Helix.Account.Controller.AccountService
  alias Helix.Account.Repo

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      worker(AccountService, []),
      worker(Repo, [])
    ]

    opts = [strategy: :one_for_one, name: Account.Supervisor]
    Supervisor.start_link(children, opts)
  end
end