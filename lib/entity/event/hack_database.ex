defmodule Helix.Entity.Event.HackDatabase do

  alias Helix.Hardware.Query.NetworkConnection, as: NetworkConnectionQuery
  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Software.Model.SoftwareType.Cracker.ProcessConclusionEvent
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Entity.Action.HackDatabase, as: HackDatabaseAction

  def cracker_conclusion(event = %ProcessConclusionEvent{}) do
    entity = EntityQuery.fetch(event.entity_id)
    server = ServerQuery.fetch(event.server_id)
    server_ip = NetworkConnectionQuery.get_server_ip(
      event.server_id,
      event.network_id)

    create_entry = fn ->
      HackDatabaseAction.create(
        entity,
        event.network_id,
        event.server_ip,
        event.server_id,
        event.server_type)
    end

    set_password = fn ->
      HackDatabaseAction.update(
        entity,
        event.network_id,
        event.server_ip,
        %{password: server.password})
    end

    if to_string(server_ip) == to_string(event.server_ip) do
      {:ok, _} = create_entry.()
      {:ok, _} = set_password.()
    end
  end
end
