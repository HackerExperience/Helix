defmodule Helix.Network.Public.Network do

  import HELL.Macros

  alias HELL.IPv4
  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Entity.Query.Database, as: DatabaseQuery
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Server.Model.Server
  alias Helix.Network.Model.Network
  alias Helix.Network.Query.Web, as: WebQuery

  @spec browse(Network.idt, String.t | IPv4.t, Server.idt) ::
    {:ok, term, relay :: %{server_id: Server.id}}
    | {:error, %{message: String.t}}
  @doc """
  Browses to an address (website or IP).  Regardless of the address type, the
  network ID must be specified. The ID of the server making the request must
  also be specified, since it may be relevant if a DNS Anycast resolution takes
  place.
  """
  def browse(network_id, address, origin_id) do
    origin_ip = get_origin_ip(network_id, origin_id)

    with \
      {:ok, {page_owner, content}, dest_ip} <-
        WebQuery.browse(network_id, address, origin_ip),
      {:ok, server_id} <- CacheQuery.from_nip_get_server(network_id, dest_ip),
      entity = %{} <- EntityQuery.fetch_by_server(server_id)
    do
      password = DatabaseQuery.get_server_password(entity, network_id, dest_ip)

      {owner_type, owner_meta} =
        case page_owner do
          :account ->
            {:vpc, nil}
          npc = {:npc, _} ->
            npc
          :clan ->
            {:clan, nil}
        end

      web_data = %{
        content: content,
        password: password,
        type: owner_type,
        subtype: owner_meta,
        nip: [network_id, dest_ip]
      }

      relay = %{
        server_id: server_id
      }

      {:ok, web_data, relay}
    else
      _ ->
        {:error, %{message: "web_not_found"}}
    end
  end

  @spec get_origin_ip(Network.id, Server.idt) ::
    IPv4.t
  docp """
  Internal helper to quickly figure out what is the IP address of the given
  server.
  """
  defp get_origin_ip(network = %Network{}, origin_id),
    do: get_origin_ip(network.network_id, origin_id)
  defp get_origin_ip(network_id, origin_id) do
    {:ok, origin_nips} = CacheQuery.from_server_get_nips(origin_id)

    origin_nips
    |> Enum.filter(&(&1.network_id == network_id))
    |> List.first()
    |> Map.get(:ip)
  end
end
