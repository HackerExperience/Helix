use Mix.Config

prefix = "${HELIX_DB_PREFIX}"

config :helix, Helix.Log.Repo,
  pool_size: "${HELIX_DB_POOL_SIZE}",
  username: "${HELIX_DB_USER}",
  password: "${HELIX_DB_PASS}",
  hostname: "${HELIX_DB_HOST}",
  database: prefix <> "_prod_log"
