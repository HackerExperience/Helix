use Mix.Config

config :software, Helix.Software.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  database: "software_service_test"