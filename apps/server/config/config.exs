use Mix.Config

config :server,
  ecto_repos: [HELM.Server.Model.Repo]
config :server, HELM.Server.Model.Repo,
  size: 4,
  adapter: Ecto.Adapters.Postgres,
  database: "server_service",
  username: System.get_env("HELIX_DB_USER") || "postgres",
  password: System.get_env("HELIX_DB_PASS") || "postgres",
  hostname: System.get_env("HELIX_DB_HOST") || "localhost"

import_config "#{Mix.env}.exs"