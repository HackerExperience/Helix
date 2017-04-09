use Mix.Config

config :helix, Helix.Endpoint,
  server: true,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false
