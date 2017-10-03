use Mix.Config

prefix = System.get_env("HELIX_DB_PREFIX") || "helix"

config :helix, Helix.Story.Repo,
  database: prefix <> "_dev_story"
