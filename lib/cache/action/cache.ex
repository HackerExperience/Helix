defmodule Helix.Cache.Action.Cache do

  alias Helix.Cache.Internal.Cache, as: CacheInternal

  def purge_server(server_id) do
    CacheInternal.purge(:server, [server_id])
  end

  def purge_storage(storage_id) do
    CacheInternal.purge(:storage, [storage_id])
  end

  def purge_component(component_id) do
    CacheInternal.purge(:component, [component_id])
  end

  def purge_nip(network_id, ip) do
    CacheInternal.purge(:network, [network_id, ip])
  end
end
