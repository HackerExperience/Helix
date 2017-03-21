use Mix.Config

config :helix_process, Helix.Process.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  database: "process_service_test"