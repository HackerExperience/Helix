use Mix.Config

config :server,
  ecto_repos: [Helix.Server.Repo]
config :server, Helix.Server.Repo,
  size: 4,
  adapter: Ecto.Adapters.Postgres,
  database: "server_service",
  username: System.get_env("HELIX_DB_USER") || "postgres",
  password: System.get_env("HELIX_DB_PASS") || "postgres",
  hostname: System.get_env("HELIX_DB_HOST") || "localhost"

import_config "#{Mix.env}.exs"