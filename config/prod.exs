use Mix.Config

config :logger,
  level: :info,
  compile_time_purge_level: :info,
  metadata: [:request_id]

config :helix, Helix.Endpoint,
  allowed_cors: ["https://api.hackerexperience.com",
                 "https://1.hackerexperience.com",
                 "https://heborn.hackerexperience.com"],
  server: true,
  url: [host: "${HELIX_ENDPOINT_URL}", port: 80],
  secret_key_base: "${HELIX_ENDPOINT_SECRET_KEY}",
  debug_errors: false
