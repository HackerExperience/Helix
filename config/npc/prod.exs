use Mix.Config

prefix = "${HELIX_DB_PREFIX}"

config :helix, Helix.NPC.Repo,
  size: "${HELIX_DB_POOL_SIZE}",
  username: "${HELIX_DB_USER}",
  password: "${HELIX_DB_PASS}",
  hostname: "${HELIX_DB_HOST}",
  database: prefix <> "_prod_npc",
  loggers: [Appsignal.Ecto, Ecto.LogEntry]
