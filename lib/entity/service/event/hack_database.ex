defmodule Helix.Entity.Service.Event.HackDatabase do

  alias Helix.Hardware.Service.API.NetworkConnection, as: NetworkConnectionAPI
  alias Helix.Server.Service.API.Server, as: ServerAPI
  alias Helix.Software.Model.SoftwareType.Cracker.ProcessConclusionEvent
  alias Helix.Entity.Service.API.Entity, as: EntityAPI
  alias Helix.Entity.Service.API.HackDatabase, as: HackDatabaseAPI

  def cracker_conclusion(event = %ProcessConclusionEvent{}) do
    entity = EntityAPI.fetch(event.entity_id)
    server = ServerAPI.fetch(event.server_id)
    server_ip = NetworkConnectionAPI.get_server_ip(
      event.server_id,
      event.network_id)

    create_entry = fn ->
      HackDatabaseAPI.create(
        entity,
        event.network_id,
        event.server_ip,
        event.server_id,
        event.server_type)
    end

    set_password = fn ->
      HackDatabaseAPI.update(
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
