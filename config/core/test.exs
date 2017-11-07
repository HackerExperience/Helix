use Mix.Config

prefix = System.get_env("HELIX_DB_PREFIX") || "helix"

config :helix, Helix.Core.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  database: prefix <> "_test_core",
  ownership_timeout: 90_000
