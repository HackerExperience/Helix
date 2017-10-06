defmodule Helix.Test.Server.Helper do

  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Server.Model.Server
  alias Helix.Server.Query.Server, as: ServerQuery

  alias Helix.Test.Network.Helper, as: NetworkHelper

  @internet NetworkHelper.internet_id()

  def get_ip(server, network_id \\ @internet)
  def get_ip(server = %Server{}, network_id),
    do: get_ip(server, network_id)
  def get_ip(server_id, network_id),
    do: ServerQuery.get_ip(server_id, network_id)

  def get_owner(server),
    do: EntityQuery.fetch_by_server(server)
end
