use Mix.Config

prefix = System.get_env("HELIX_DB_PREFIX") || "helix"

config :helix_npc, Helix.NPC.Repo,
  database: prefix <> "_dev_npc"
