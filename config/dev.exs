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
