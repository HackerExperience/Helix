use Mix.Config

config :account, Helix.Account.Repo,
  size: 2,
  username: System.get_env("HELIX_DB_USER") || "postgres",
  password: System.get_env("HELIX_DB_PASS") || "postgres",
  hostname: System.get_env("HELIX_DB_HOST") || "localhost",
  database: "account_service_dev"