defmodule Helix.Network.Query.Web do

  alias HELL.IPv4
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Entity.Query.Database, as: DatabaseQuery
  alias Helix.Hardware.Query.NetworkConnection, as: NetworkConnectionQuery
  alias Helix.Network.Query.DNS, as: DNSQuery
  alias Helix.Universe.NPC.Model.NPC
  alias Helix.Network.Internal.Web, as: WebInternal
  alias Helix.Universe.NPC.Query.NPC, as: NPCQuery

  def browse(network, address, origin) do
    case IPv4.parse_address(address) do
      {:ok, _} ->
        browse_ip(network, address)
      :error ->
        case DNSQuery.resolve(address, origin) do
          {:ok, ip} ->
            browse_ip(network, ip)
          :nxdomain ->
            {:error, :nxdomain}
        end
    end
  end

  def browse_ip(network, ip) do
    with \
      server = %{} <- NetworkConnectionQuery.get_server_by_ip(network, ip),
      entity = %{} <- EntityQuery.fetch_server_owner(server.server_id)
    do
      {:ok, serve(ip, entity.entity_id, entity.entity_type)}
    else
      _ ->
        {:error, :not_found}
    end
  end

  def serve(server_ip, entity_id, entity_type) do
    case entity_type do
      :npc ->
        {:npc, serve_npc(server_ip, entity_id)}
      _ ->
        {:vpc, serve_vpc(server_ip)}
    end
  end

  def serve_vpc(ip) do
    WebInternal.get_content({:vpc, ip})
  end

  def serve_npc(ip, npc_id) do
    npc = NPCQuery.fetch(npc_id)
    WebInternal.get_content({:npc, ip, npc})
  end

end
