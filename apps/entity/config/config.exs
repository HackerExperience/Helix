use Mix.Config

config :entity,
  ecto_repos: [HELM.Entity.Model.Repo]

config :entity, HELM.Entity.Model.Repo,
  size: 4,
  adapter: Ecto.Adapters.Postgres,
  database: "entity_service",
  username: System.get_env("HELIX_DB_USER") || "postgres",
  password: System.get_env("HELIX_DB_PASS") || "postgres",
  hostname: System.get_env("HELIX_DB_HOST") || "localhost"

import_config "#{Mix.env}.exs"