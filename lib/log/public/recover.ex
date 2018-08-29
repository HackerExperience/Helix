defmodule Helix.Log.Public.Recover do

  alias Helix.Log.Action.Flow.Recover, as: RecoverFlow

  defdelegate global(gateway, endpoint, recover, entity, conn_info, relay),
    to: RecoverFlow

  defdelegate custom(gateway, endpoint, log, recover, entity, conn_info, relay),
    to: RecoverFlow
end
