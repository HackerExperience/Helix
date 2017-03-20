use Mix.Config

config :entity, Helix.Entity.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  database: "entity_service_test"