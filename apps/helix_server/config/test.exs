use Mix.Config

config :helix_server, Helix.Server.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  database: "server_service_test"