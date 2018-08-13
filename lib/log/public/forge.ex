defmodule Helix.Log.Public.Forge do

  alias Helix.Log.Action.Flow.Forge, as: ForgeFlow

  defdelegate create(gateway, endpoint, log_info, forger, conn, relay),
    to: ForgeFlow

  defdelegate edit(gtw, endpoint, log, log_info, forger, entity, conn, relay),
    to: ForgeFlow
end
