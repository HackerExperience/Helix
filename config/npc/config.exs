use Mix.Config

config :helix, Helix.NPC.Repo,
  priv: "priv/repo/npc",
  pool_size: 3,
  adapter: Ecto.Adapters.Postgres,
  username: System.get_env("HELIX_DB_USER") || "postgres",
  password: System.get_env("HELIX_DB_PASS") || "postgres",
  hostname: System.get_env("HELIX_DB_HOST") || "localhost",
  types: HELL.PostgrexTypes
