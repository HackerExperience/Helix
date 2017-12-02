use Mix.Config

config :logger,
  level: :warn,
  compile_time_purge_level: :warn

config :helix, Helix.Endpoint,
  server: false,
  allowed_cors: "*",
  url: [host: "localhost", port: 4001],
  https: [
    port: 4001,
    otp_app: :helix,
    keyfile: "priv/dev/ssl.key",
    certfile: "priv/dev/ssl.crt"
  ],
  debug_errors: false

config :helf,
  driver: :sync

config :logger,
  backends: [:console],
  level: :warn
