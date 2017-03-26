use Mix.Config

prefix = System.get_env("HELIX_DB_PREFIX") || "helix"

config :helix_npc, Helix.NPC.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  database: prefix <> "_test_npc"
