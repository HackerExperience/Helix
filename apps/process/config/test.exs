use Mix.Config

config :process, Helix.Process.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  database: "process_service_test"