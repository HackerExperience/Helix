use Mix.Config

config :logger,
  level: :info,
  compile_time_purge_level: :info,
  metadata: [:request_id]

config :helix, Helix.Endpoint,
  server: true,
  instrumenters: [Appsignal.Phoenix.Instrumenter],
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

config :appsignal, :config,
  name: "Helix",
  env: :prod
