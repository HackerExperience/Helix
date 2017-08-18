defmodule Helix.Network.Websocket.Routes do

  alias Helix.Websocket.Socket, warn: false
  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Entity.Query.Database, as: DatabaseQuery
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Server.Query.Server, as: ServerQuery

  # TODO: Check if player's gateway is connected to specified network
  def browse_ip(socket, %{"network_id" => network, "ip" => ip}) do
    with \
      {:ok, server_id} <- CacheQuery.from_nip_get_server(network, ip),
      server = %{} <- ServerQuery.fetch(server_id),
      entity = %{} <- EntityQuery.fetch_by_server(server_id)
    do
      password = DatabaseQuery.get_server_password(entity, network, ip)

      # TODO: move this to the presentation layer
      data = %{
        server_id: server_id,
        server_type: server.server_type,
        entity_type: entity.entity_type,
        # Defaults to nil
        password: password
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
