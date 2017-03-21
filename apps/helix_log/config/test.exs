use Mix.Config

config :helix_log, Helix.Log.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  database: "log_service_test"