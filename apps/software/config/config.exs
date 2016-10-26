use Mix.Config

config :software,
  ecto_repos: [HELM.Software.Model.Repo]
config :software, HELM.Software.Model.Repo,
  size: 4,
  adapter: Ecto.Adapters.Postgres,
  database: "software_service",
  username: System.get_env("HELIX_DB_USER") || "postgres",
  password: System.get_env("HELIX_DB_PASS") || "postgres",
  hostname: System.get_env("HELIX_DB_HOST") || "localhost"

import_config "#{Mix.env}.exs"