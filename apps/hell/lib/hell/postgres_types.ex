types = [
  {HELL.PostgresTypes.LTree, :copy},
  {HELL.PostgresTypes.LQuery, :copy},
  {HELL.PostgresTypes.LTXTQuery, :copy}
] ++ Ecto.Adapters.Postgres.extensions()

Postgrex.Types.define(HELL.PostgresTypes, types, json: Poison)