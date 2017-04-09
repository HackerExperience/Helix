use Mix.Config

config :logger,
  level: :warn,
  compile_time_purge_level: :warn

config :helix, Helix.Endpoint,
  http: [port: 4001],
  server: false
