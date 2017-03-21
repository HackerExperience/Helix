use Mix.Config

config :log, Helix.Log.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  database: "log_service_test"