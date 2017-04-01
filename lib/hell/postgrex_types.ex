types = [{HELL.Postgrex.LTree, []}] ++ Ecto.Adapters.Postgres.extensions()

Postgrex.Types.define(HELL.PostgrexTypes, types, json: Poison)
