use Mix.Config

config :log, Helix.Log.Repo,
  size: "${HELIX_DB_POOL_SIZE}",
  username: "${HELIX_DB_USER}",
  password: "${HELIX_DB_PASS}",
  hostname: "${HELIX_DB_HOST}"
