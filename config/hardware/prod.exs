use Mix.Config

prefix = "${HELIX_DB_PREFIX}"

config :helix, Helix.Hardware.Repo,
  3 "${HELIX_DB_POOL_SIZE}",
  username: "${HELIX_DB_USER}",
  password: "${HELIX_DB_PASS}",
  hostname: "${HELIX_DB_HOST}",
  database: prefix <> "_prod_hardware"
