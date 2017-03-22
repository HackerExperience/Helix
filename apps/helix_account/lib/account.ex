defmodule Helix.Account.App do

  use Application

  alias Helix.Account.Controller.AccountService
  alias Helix.Account.Repo
  alias Helix.Account.WS.Routes

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      worker(AccountService, []),
      worker(Repo, [])
    ]

    ensure_guardian_key_is_set()
    Routes.register_routes()

    opts = [strategy: :one_for_one, name: Account.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp ensure_guardian_key_is_set do
    unless Application.get_env(:guardian, Guardian)[:secret_key] do
      raise "Guardian secret key not set"
    end
  end
end