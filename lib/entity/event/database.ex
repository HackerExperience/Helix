defmodule Helix.Entity.Event.Database do

  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Entity.Action.Database, as: DatabaseAction
  alias Helix.Entity.Query.Database, as: DatabaseQuery
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Entity.Repo

  alias Helix.Software.Model.SoftwareType.Cracker.ProcessConclusionEvent

  def cracker_conclusion(event = %ProcessConclusionEvent{}) do
    entity = EntityQuery.fetch(event.entity_id)
    server = ServerQuery.fetch(event.server_id)
    server_ip = ServerQuery.get_ip(event.server_id, event.network_id)

    create_entry = fn ->
      DatabaseAction.create(
        entity,
        event.network_id,
        event.server_ip,
        server,
        event.server_type)
    end

    set_password = fn ->
      entity
      |> DatabaseQuery.get_server_entries(server)
      |> Enum.each(&DatabaseAction.update(&1, %{password: server.password}))
    end

    if to_string(server_ip) == to_string(event.server_ip) do
      Repo.transaction fn ->
        {:ok, _} = create_entry.()
        :ok = set_password.()
      end
    end
  end
end
