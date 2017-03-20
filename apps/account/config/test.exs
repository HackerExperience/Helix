use Mix.Config

config :comeonin, :bcrypt_log_rounds, 2

config :account, Helix.Account.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  database: "account_service_test"