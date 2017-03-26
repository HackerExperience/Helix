use Mix.Config

prefix = System.get_env("HELIX_DB_PREFIX") || "helix"

config :comeonin, :bcrypt_log_rounds, 2

config :helix_account, Helix.Account.Repo,
  database: prefix <> "_dev_account"

config :guardian, Guardian,
  secret_key: System.get_env("HELIX_JWK_KEY") || "abc123++"
