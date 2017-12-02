use Mix.Config

prefix = "${HELIX_DB_PREFIX}"

config :bcrypt_elixir, :log_rounds, 14

config :helix, Helix.Account.Repo,
  pool_size: "${HELIX_DB_POOL_SIZE}",
  username: "${HELIX_DB_USER}",
  password: "${HELIX_DB_PASS}",
  hostname: "${HELIX_DB_HOST}",
  database: prefix <> "_prod_account",
  timeout: 90_000
