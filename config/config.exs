use Mix.Config

config :helix,
  ecto_repos: [
    Helix.Account.Repo,
    Helix.Entity.Repo,
    Helix.Hardware.Repo,
    Helix.Log.Repo,
    Helix.Network.Repo,
    Helix.NPC.Repo,
    Helix.Process.Repo,
    Helix.Server.Repo,
    Helix.Software.Repo
  ]

default_key = "asdfghjklzxcvbnm,./';[]-=1234567890!"
config :helix, Helix.Endpoint,
  secret_key_base: System.get_env("HELIX_ENDPOINT_SECRET_KEY") || default_key,
  pubsub: [
    adapter: Phoenix.PubSub.PG2,
    pool_size: 1,
    name: Helix.Endpoint.PubSub
  ]

config :distillery, no_warn_missing: [:burette]

import_config "#{Mix.env}.exs"
import_config "*/config.exs"
import_config "*/#{Mix.env}.exs"
