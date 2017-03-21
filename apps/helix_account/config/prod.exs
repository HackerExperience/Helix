use Mix.Config

config :comeonin, :bcrypt_log_rounds, 14

config :helix_account, Helix.Account.Repo,
  size: "${HELIX_DB_POOL_SIZE}",
  username: "${HELIX_DB_USER}",
  password: "${HELIX_DB_PASS}",
  hostname: "${HELIX_DB_HOST}",
  database: "account_service"

config :guardian, Guardian,
  secret_key: System.get_env("HELIX_JWK_KEY")