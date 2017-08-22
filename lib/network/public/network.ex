defmodule Helix.Network.Public.Network do

  alias HELL.IPv4
  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Entity.Query.Database, as: DatabaseQuery
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Server.Model.Server
  alias Helix.Network.Model.Network
  alias Helix.Network.Query.Web, as: WebQuery

  @spec browse(Network.id, String.t | IPv4.t, Server.idt) ::
    {:ok, term}
    | {:error, %{message: String.t}}
  def browse(network_id, address, origin_id) do
    origin_ip = get_origin_ip(network_id, origin_id)

    with \
      {:ok, webserver, dest_ip} <-
        WebQuery.browse(network_id, address, origin_ip),
      {:ok, server_id} <- CacheQuery.from_nip_get_server(network_id, dest_ip),
      entity = %{} <- EntityQuery.fetch_by_server(server_id)
    do
      password = DatabaseQuery.get_server_password(entity, network_id, dest_ip)

      web_data = %{
        webserver: webserver,
        password: password
      }

      {:ok, web_data}
    else
      _ ->
        {:error, %{message: "web_not_found"}}
    end
  end

  @spec get_origin_ip(Network.id, Server.idt) ::
    IPv4.t
  defp get_origin_ip(network_id, origin_id) do
    {:ok, origin_nips} = CacheQuery.from_server_get_nips(origin_id)

    origin_nips
    |> Enum.filter(&(&1.network_id == network_id))
    |> List.first()
    |> Map.get(:ip)
  end
end