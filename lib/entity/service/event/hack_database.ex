defmodule Helix.Entity.Service.Event.HackDatabase do

  alias Helix.Software.Model.SoftwareType.Cracker.ProcessConclusionEvent
  alias Helix.Entity.Service.API.Entity, as: EntityAPI
  alias Helix.Entity.Service.API.HackDatabase, as: HackDatabaseAPI

  def cracker_conclusion(event = %ProcessConclusionEvent{}) do
    entity = EntityAPI.fetch(event.entity_id)

    # TODO: check that the target server has the specified ip on the network
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
        # TODO: password
        %{password: ""})
    end

    {:ok, _} = create_entry.()
    {:ok, _} = set_password.()
  end
end
