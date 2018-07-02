defmodule Helix.Application do

  use Application

  require Logger

  import Supervisor.Spec

  def start(_type, _args) do
    children = [
      supervisor(Helix.Endpoint, []),
      supervisor(Helix.Application.DomainsSupervisor, [])
    ]

    validate_timber_key()
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

  defp validate_timber_key do
    if Application.get_env(:helix, :env) == :prod do
      {:system, api_key} = Application.get_env(:timber, :api_key)

      ignore? = System.get_env("YOLO_IGNORE_LOGGING") == "true"

      if (api_key == "${TIMBER_API_KEY}" or api_key == "") and not ignore? do
        raise """

        Missing environment variable `TIMBER_API_KEY`.

        Set the `TIMBER_API_KEY` env var or ignore this verification by setting
        `YOLO_IGNORE_LOGGING` to `true`.

        """
      else
        IO.puts "Skipping logging..."
      end
    end
  end
end

defmodule Helix.Application.DomainsSupervisor do

  use Supervisor
  use Helix.Logger

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  def init(_) do
    children = [
      supervisor(Helix.Account.Supervisor, []),
      supervisor(Helix.Cache.Supervisor, []),
      supervisor(Helix.Client.Supervisor, []),
      supervisor(Helix.Core.Supervisor, []),
      supervisor(Helix.Entity.Supervisor, []),
      supervisor(Helix.Event.Supervisor, []),
      supervisor(Helix.Log.Supervisor, []),
      supervisor(Helix.Network.Supervisor, []),
      supervisor(Helix.Notification.Supervisor, []),
      supervisor(Helix.Process.Supervisor, []),
      supervisor(Helix.Server.Supervisor, []),
      supervisor(Helix.Software.Supervisor, []),
      supervisor(Helix.Story.Supervisor, []),
      supervisor(Helix.Universe.Supervisor, [])
    ]

    log :helix_started, :helix

    supervise(children, strategy: :one_for_one)
  end
end
