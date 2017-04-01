defmodule Helix.Account.Supervisor do

  use Supervisor

  alias Helix.Account.Repo
  alias Helix.Account.WS.Routes

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  def init(_) do
    children = [
      worker(Repo, [])
    ]

    validate_guardian_config()
    Routes.register_routes()
    Routes.register_topics()

    supervise(children, strategy: :one_for_one)
  end

  defp validate_guardian_config do
    config = Application.get_env(:guardian, Guardian)

    # Make sure we aren't accidentally using an empty secret key
    unless is_binary(config[:secret_key]) do
      raise "Guardian secret key not set"
    end

    if Enum.empty?(config[:allowed_algos]) do
      raise "must set at least one allowed algorithm for JWT"
    end

    # Make sure we aren't using JWT'S "none" encryption algorithm
    if Enum.any?(config[:allowed_algos], &(String.downcase(&1) == "none")) do
      raise "can't use \"none\" as JWT algorithm"
    end
  end
end
