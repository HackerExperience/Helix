types = [
  {HELL.PostgresTypes.LTree, :copy}
] ++ Ecto.Adapters.Postgres.extensions()

Postgrex.Types.define(HELL.PostgresTypes, types, json: Poison)