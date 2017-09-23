defmodule Helix.Network.Query.Web do

  alias HELL.IPv4
  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Universe.NPC.Model.NPCType
  alias Helix.Universe.NPC.Query.NPC, as: NPCQuery
  alias Helix.Network.Model.Network
  alias Helix.Network.Query.DNS, as: DNSQuery

  @type page_content ::
    term

  @type page_owner ::
    :account
    | :clan
    | {:npc, NPCType.types}

  @spec browse(Network.idt, String.t | IPv4.t, IPv4.t) ::
    {:ok, {page_owner, page_content}, IPv4.t}
    | {:error, {:ip, :notfound}}
    | {:error, {:domain, :notfound}}
  @doc """
  Browses to the specified address, which resides within the given network.

  The server making the request is relevant because, in case of a DNS Anycast
  query, it will be used to determine the nearest server.
  """
  def browse(network, address, origin) do
    if IPv4.valid?(address) do
      browse_ip(network, address)
    else
      case DNSQuery.resolve(network, address, origin) do
        {:ok, ip} ->
          browse_ip(network, ip)
        error ->
          error
      end
    end
  end

  @spec browse_ip(Network.idt, IPv4.t) ::
    {:ok, {page_owner, page_content}, IPv4.t}
    | {:error, {:ip, :notfound}}
  defp browse_ip(network, ip) do
    with \
      {:ok, server_id} <- CacheQuery.from_nip_get_server(network, ip),
      server = %{} <- ServerQuery.fetch(server_id),
      entity = %{} <- EntityQuery.fetch_by_server(server.server_id),
      {:ok, content} <- serve(network, ip)
    do
      {:ok, {get_page_owner(entity), content}, ip}
    else
      _ ->
        {:error, {:ip, :notfound}}
    end
  end

  @spec get_page_owner(Entity.t) ::
    page_owner
  defp get_page_owner(%Entity{entity_type: :account}),
    do: :account
  defp get_page_owner(%Entity{entity_type: :clan}),
    do: :clan
  defp get_page_owner(entity = %Entity{entity_type: :npc}) do
    npc = NPCQuery.fetch(entity.entity_id)
    {:npc, npc.npc_type}
  end

  @spec serve(Network.idt, IPv4.t) ::
    {:ok, page_content}
    | {:error, :notfound}
  @doc """
  Returns the webserver content of the given NIP.
  """
  def serve(network, ip) do
    case CacheQuery.from_nip_get_web(network, ip) do
      {:ok, content} ->
        {:ok, content}
      _ ->
        {:error, :notfound}
    end
  end
end
