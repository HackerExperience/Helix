use Mix.Config

prefix = System.get_env("HELIX_DB_PREFIX") || "helix"

config :helix_hardware, Helix.Hardware.Repo,
  database: prefix <> "_dev_hardware"
