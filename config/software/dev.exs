use Mix.Config

prefix = System.get_env("HELIX_DB_PREFIX") || "helix"

config :helix, Helix.Software.Repo,
  database: prefix <> "_dev_software"
