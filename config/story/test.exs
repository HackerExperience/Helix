use Mix.Config

prefix = System.get_env("HELIX_DB_PREFIX") || "helix"

config :helix, Helix.Story.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  database: prefix <> "_test_story"
