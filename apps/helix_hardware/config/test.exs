use Mix.Config

config :helix_hardware, Helix.Hardware.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  database: "hardware_service_test"