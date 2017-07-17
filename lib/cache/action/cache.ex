defmodule Helix.Cache.Action.Cache do

  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Cache.Internal.Cache, as: CacheInternal
  alias Helix.Cache.Query.Cache, as: CacheQuery

  def purge_server(server_id) do
    CacheInternal.purge(:server, [server_id])
  end

  def purge_storage(storage_id) do
    {:ok, server_id} = CacheQuery.from_storage_get_server(storage_id)
    purge_storage(storage_id, server_id)
  end
  def purge_storage(storage_id, server_id) do
    CacheInternal.mark_as_purged(:storage, [storage_id])
    CacheInternal.purge(:server, [server_id])
  end

  def purge_component(component_id) do
    {:ok, mobo_id} = CacheQuery.from_component_get_motherboard(component_id)
    server = ServerQuery.fetch_by_motherboard(mobo_id)
    purge_component(component_id, server.server_id)
  end
  def purge_component(component_id, server_id) do
    CacheInternal.mark_as_purged(:component, [component_id])
    CacheInternal.purge(:server, [server_id])
  end

  def purge_nip(network_id, ip) do
    case CacheQuery.from_nip_get_server(network_id, ip) do
      {:ok, server_id} ->
        purge_nip(network_id, ip, server_id)
      {:error, _} ->
        CacheInternal.mark_as_purged(:network, [network_id, ip])
    end
  end
  def purge_nip(network_id, ip, server_id) do
    CacheInternal.mark_as_purged(:network, [network_id, ip])
    CacheInternal.purge(:server, [server_id])
  end
end
