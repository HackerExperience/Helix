use Mix.Config

config :comeonin, :bcrypt_log_rounds, 2

config :helix_account, Helix.Account.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  size: 2,
  username: System.get_env("HELIX_DB_USER") || "postgres",
  password: System.get_env("HELIX_DB_PASS") || "postgres",
  hostname: System.get_env("HELIX_DB_HOST") || "localhost",
  database: "account_service_test"