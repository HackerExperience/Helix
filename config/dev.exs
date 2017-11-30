use Mix.Config

config :helix, Helix.Endpoint,
  server: true,
  allowed_cors: ~r/http?.*localhost*/,
  url: [
    host: "localhost",
    port: 4000
  ],
  https: [
    port: 4000,
    otp_app: :helix,
    keyfile: "priv/dev/ssl.key",
    certfile: "priv/dev/ssl.crt"
  ],
  debug_errors: true,
  code_reloader: false,
  check_origin: false

config :logger,
  backends: [:console, Timber.LoggerBackends.HTTP, {LoggerFileBackend, :debug}],
  utc_log: true,
  level: :info

config :logger, :debug,
  path: "./helix.log",
  level: :debug

# Enable Timber logging on `dev` simply by setting the env var below
config :timber,
  api_key: {:system, "TIMBER_LOGS_KEY"}
