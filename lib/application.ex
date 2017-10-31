defmodule Helix.Application do

  use Application

  import Supervisor.Spec

  def start(_type, _args) do
    children = [
      # worker(HELF.Broker, []),
      supervisor(Helix.Endpoint, []),
      supervisor(Helix.Application.DomainsSupervisor, [])
    ]

    validate_token_key()

    opts = [strategy: :one_for_one, name: Helix.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp validate_token_key do
    config = Application.get_env(:helix, Helix.Endpoint)
    secret_key = config[:secret_key_base]

    # If there is no env set, distillery will pass the env name forward
    # without any change
    env_set? = secret_key != "${HELIX_ENDPOINT_SECRET_KEY}"

    unless is_binary(secret_key) and byte_size(secret_key) > 20 and env_set? do
      raise """

      Helix.Endpoint `secret_key_base` config is not set or the key is too short

      To fix this, set the environment variable `HELIX_ENDPOINT_SECRET_KEY`
      with the desired key. It should be longer than 20 characters to ensure
      be secure

      Example:
      HELIX_ENDPOINT_SECRET_KEY="myVerySeCr3tK3y!!++=" mix run
      """
    end
  end
end

defmodule Helix.Application.DomainsSupervisor do

  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  def init(_) do
    children = [
      supervisor(Helix.Account.Supervisor, []),
      supervisor(Helix.Cache.Supervisor, []),
      supervisor(Helix.Core.Supervisor, []),
      supervisor(Helix.Entity.Supervisor, []),
      supervisor(Helix.Hardware.Supervisor, []),
      supervisor(Helix.Log.Supervisor, []),
      supervisor(Helix.Network.Supervisor, []),
      supervisor(Helix.Universe.Supervisor, []),
      supervisor(Helix.Process.Supervisor, []),
      supervisor(Helix.Server.Supervisor, []),
      supervisor(Helix.Software.Supervisor, []),
      supervisor(Helix.Story.Supervisor, [])
    ]

    supervise(children, strategy: :one_for_one)
  end
end
