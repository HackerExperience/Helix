use Mix.Config

config :helf, :router_port, System.get_env("HELF_ROUTER_PORT") || 8080

import_config "#{Mix.env}.exs"