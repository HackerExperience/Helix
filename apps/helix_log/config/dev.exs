use Mix.Config

prefix = System.get_env("HELIX_DB_PREFIX") || "helix"

config :helix_log, Helix.Log.Repo,
  database: prefix <> "_dev_log"
