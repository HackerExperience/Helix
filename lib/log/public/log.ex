defmodule Helix.Log.Public.Log do

  alias Helix.Server.Model.Server
  alias Helix.Log.Query.Log, as: LogQuery

  @spec index(Server.id) ::
    [map]
  def index(server_id) do
    logs = LogQuery.get_logs_on_server(server_id)

    # HACK: FIXME: This belongs to a viewable protocol. We're doing it as it
    #   is now so it works before we do the real work (?)
    Enum.map(logs, &Map.take(&1, [:log_id, :message, :inserted_at]))
  end
end
