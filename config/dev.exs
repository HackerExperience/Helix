use Mix.Config

config :helix, Helix.Endpoint,
  server: true,
  allowed_cors: ~r/http?.*localhost*/,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false
