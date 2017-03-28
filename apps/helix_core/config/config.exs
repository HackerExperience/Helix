use Mix.Config

config :helix_core, ecto_repos: []

config :helix_core, :router_port, System.get_env("HELF_ROUTER_PORT") || 8080

import_config "#{Mix.env}.exs"
