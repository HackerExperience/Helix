use Mix.Config

config :helix, Helix.Endpoint,
  server: true,
  allowed_cors: [
    "https://api.hackerexperience.com",
    "https://1.hackerexperience.com",
    "https://heborn.hackerexperience.com"
  ],
  url: [
    host: "${HELIX_ENDPOINT_URL}",
    port: 4000
  ],
  https: [
    port: 4000,
    otp_app: :helix,
    keyfile: "${HELIX_SSL_KEYFILE}",
    certfile: "${HELIX_SSL_CERTFILE}"
  ],
  secret_key_base: "${HELIX_ENDPOINT_SECRET_KEY}",
  debug_errors: false,
  check_origin: false

config :helix, :migration_token, "${HELIX_MIGRATION_TOKEN}"

config :logger,
  compile_time_purge_level: :info,
  metadata: [:request_id],
  backends: [
    Timber.LoggerBackends.HTTP,
    {LoggerFileBackend, :warn},
    {LoggerFileBackend, :error}
  ],
  utc_log: true,
  level: :info

config :logger, :warn,
  path: "/var/log/helix/warn.log",
  level: :warn

config :logger, :error,
  path: "/var/log/helix/error.log",
  level: :error

config :timber,
  api_key: {:system, "${TIMBER_API_KEY}"}
