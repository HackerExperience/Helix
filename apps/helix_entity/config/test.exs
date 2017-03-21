use Mix.Config

config :helix_entity, Helix.Entity.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  database: "entity_service_test"