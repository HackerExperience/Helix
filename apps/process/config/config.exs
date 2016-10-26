use Mix.Config

config :process,
  ecto_repos: [HELM.Process.Model.Repo]
config :process, HELM.Process.Model.Repo,
  size: 4,
  adapter: Ecto.Adapters.Postgres,
  database: "process_service",
  username: System.get_env("HELIX_DB_USER") || "postgres",
  password: System.get_env("HELIX_DB_PASS") || "postgres",
  hostname: System.get_env("HELIX_DB_HOST") || "localhost"

import_config "#{Mix.env}.exs"