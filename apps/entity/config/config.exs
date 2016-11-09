use Mix.Config

config :entity,
  ecto_repos: [HELM.Entity.Repo]

config :entity, HELM.Entity.Repo,
  size: 4,
  adapter: Ecto.Adapters.Postgres,
  database: "entity_service",
  username: System.get_env("HELIX_DB_USER") || "postgres",
  password: System.get_env("HELIX_DB_PASS") || "postgres",
  hostname: System.get_env("HELIX_DB_HOST") || "localhost",
  extensions: [
    {Postgrex.Extensions.Network, nil}
  ]

import_config "#{Mix.env}.exs"