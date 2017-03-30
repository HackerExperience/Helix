defmodule Helix.Account.App do

  use Application

  alias Helix.Account.Repo
  alias Helix.Account.WS.Routes

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      worker(Repo, [])
    ]

    validate_guardian_config()
    Routes.register_routes()
    Routes.register_topics()

    opts = [strategy: :one_for_one, name: Account.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp validate_guardian_config do
    # Make sure we aren't accidentally using an empty secret key
    unless Application.get_env(:guardian, Guardian)[:secret_key] do
      raise "Guardian secret key not set"
    end

    # Make sure we aren't using JWT'S "none" encryption algorithm
    allowed_algos = Application.get_env(:guardian, Guardian)[:allowed_algos]
    if "none" in allowed_algos do
      raise "Can't use 'none' as JWT algorithm"
    end
  end
end
