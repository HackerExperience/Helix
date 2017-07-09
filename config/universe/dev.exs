use Mix.Config

prefix = System.get_env("HELIX_DB_PREFIX") || "helix"

config :helix, Helix.Universe.Repo,
  database: prefix <> "_dev_universe"
