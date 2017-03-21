use Mix.Config

config :helix_npc, Helix.NPC.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  database: "npc_service_test"