use Mix.Config

config :logger,
  level: :info,
  compile_time_purge_level: :info

config :helix, Helix.Endpoint,
  server: true,
  secret_key_base: "${HELIX_ENDPOINT_SECRET_KEY}",
  debug_errors: false
