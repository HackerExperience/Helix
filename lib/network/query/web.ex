defmodule Helix.Network.Query.Web do

  alias HELL.IPv4
  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Entity.Query.Database, as: DatabaseQuery
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

  defp browse_ip(network, ip) do
    with \
      {:ok, server_id} <- CacheQuery.from_nip_get_server(network, ip),
      server = %{} <- ServerQuery.fetch(server_id),
      entity = %{} <- EntityQuery.fetch_server_owner(server.server_id)
    do
      {:ok, WebInternal.serve(ip, entity)}
    else
      _ ->
        {:error, :not_found}
    end
  end
end
