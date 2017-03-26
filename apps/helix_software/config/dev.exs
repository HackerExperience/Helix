use Mix.Config

prefix = System.get_env("HELIX_DB_PREFIX") || "helix"

config :helix_software, Helix.Software.Repo,
  database: prefix <> "_dev_software"
