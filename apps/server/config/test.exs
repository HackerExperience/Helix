use Mix.Config

config :server, Helix.Server.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  database: "server_service_test"