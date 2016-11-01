use Mix.Config

config :helf_router, :port, System.get_env("HELF_ROUTER_PORT") || 8080

import_config "#{Mix.env}.exs"