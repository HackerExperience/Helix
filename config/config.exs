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

config :helix, :router_port, System.get_env("HELF_ROUTER_PORT") || 8080

config :distillery, no_warn_missing: [:burette]

import_config "#{Mix.env}.exs"
import_config "*/config.exs"
import_config "*/#{Mix.env}.exs"
