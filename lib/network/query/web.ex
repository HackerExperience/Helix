defmodule Helix.Network.Query.Web do

  alias HELL.IPv4
  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Network.Internal.Web, as: WebInternal
  alias Helix.Network.Model.Network
  alias Helix.Network.Query.DNS, as: DNSQuery

  @spec browse(Network.idtb, (String.t | IPv4.t), IPv4.t) ::
    {:ok, {:npc | :vpc, term}}
    | {:error, :notfound}
    | {:error, :nxdomain}
  def browse(network, address, origin) do
    case IPv4.parse_address(address) do
      {:ok, _} ->
        browse_ip(network, address)
      :error ->
        case DNSQuery.resolve(network, address, origin) do
          {:ok, ip} ->
            browse_ip(network, ip)
          :nxdomain ->
            {:error, :nxdomain}
        end
    end
  end

  @spec browse_ip(Network.idtb, IPv4.t) ::
    {:ok, {:npc | :vpc, term}}
    | {:error, :notfound}
  defp browse_ip(network, ip) do
    with \
      {:ok, server_id} <- CacheQuery.from_nip_get_server(network, ip),
      server = %{} <- ServerQuery.fetch(server_id),
      entity = %{} <- EntityQuery.fetch_by_server(server.server_id),
      {:ok, content} <- WebInternal.serve(network, ip)
    do
      {:ok, {entity.entity_type, content}}
    else
      _ ->
        {:error, :notfound}
    end
  end
end
