defmodule Helix.Test.Server.Helper do

  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Server.Model.Server
  alias Helix.Server.Query.Server, as: ServerQuery

  alias Helix.Test.Network.Helper, as: NetworkHelper

  @internet NetworkHelper.internet_id()

  def get_ip(server, network_id \\ @internet)
  def get_ip(server = %Server{}, network_id),
    do: get_ip(server.server_id, network_id)
  def get_ip(server_id = %Server.ID{}, network_id),
    do: ServerQuery.get_ip(server_id, network_id)

  def get_owner(server),
    do: EntityQuery.fetch_by_server(server)

  def get_nip(server = %Server{}),
    do: get_nip(server.server_id)
  def get_nip(server_id = %Server.ID{}),
      do: get_all_nips(server_id) |> List.first()

  def get_all_nips(server = %Server{}),
    do: get_all_nips(server.server_id)
  def get_all_nips(server_id = %Server.ID{}),
    do: CacheQuery.from_server_get_nips!(server_id)
end
