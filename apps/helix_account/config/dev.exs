use Mix.Config

config :comeonin, :bcrypt_log_rounds, 2

config :helix_account, Helix.Account.Repo,
  database: "account_service_dev"

config :guardian, Guardian,
  secret_key: System.get_env("HELIX_JWK_KEY") || "abc123++"