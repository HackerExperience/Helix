use Mix.Config

config :entity,
  ecto_repos: [Helix.Entity.Repo]

config :entity, Helix.Entity.Repo,
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