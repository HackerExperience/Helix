defmodule Helix.Network.Websocket.Routes do

  alias Helix.Websocket.Socket, warn: false
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Entity.Query.Database, as: DatabaseQuery
  alias Helix.Cache.Query.Cache, as: CacheQuery

  # TODO: Check if player's gateway is connected to specified network
  def browse_ip(socket, %{"network_id" => network, "ip" => ip}) do
    # FIXME
    account =
      socket.assigns.account
      |> EntityQuery.get_entity_id()
      |> EntityQuery.fetch()

    with \
      {:ok, server} <- CacheQuery.from_nip_get_server(network, ip),
      entity = %{} <- EntityQuery.fetch_by_server(server.server_id)
    do
      database_entry = DatabaseQuery.fetch_server_record(
        account,
        server.server_id)

      # TODO: move this to the presentation layer
      data = %{
        server_id: server.server_id,
        server_type: server.server_type,
        entity_type: entity.entity_type,
        # Defaults to nil
        password: database_entry[:password]
      }

      return = %{
        status: :success,
        data: data
      }

      {:reply, {:ok, return}, socket}
    else
      _ ->
        return = %{
          status: :error,
          data: %{message: "not found"}
        }

        {:reply, {:error, return}, socket}
    end
  end
end
