use Mix.Config

prefix = System.get_env("HELIX_DB_PREFIX") || "helix"

config :helix, Helix.Network.Repo,
  database: prefix <> "_dev_network"
