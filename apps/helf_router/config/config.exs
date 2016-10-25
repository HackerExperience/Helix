use Mix.Config

# TODO: change this to helf_router
config :helf,
  router_port: 8080

import_config "#{Mix.env}.exs"