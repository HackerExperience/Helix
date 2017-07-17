defmodule Helix.Cache.Query.Cache do
  @moduledoc """
  Inter-domain Cache Query API.

  Lookups are transparent to cache misses, meaning that they will automatically
  populate the cache and then reply with the requested data.
  """

  alias Helix.Cache.Internal.Cache, as: CacheInternal

  def from_server_get_all(server_id) do
    CacheInternal.lookup(:server, [server_id])
  end

  def from_server_get_nips(server_id) do
    CacheInternal.lookup({:server, :nips}, [server_id])
  end

  def from_server_get_storages(server_id) do
    CacheInternal.lookup({:server, :storages}, [server_id])
  end

  def from_server_get_resources(server_id) do
    CacheInternal.lookup({:server, :resources}, [server_id])
  end

  def from_server_get_components(server_id) do
    CacheInternal.lookup({:server, :components}, [server_id])
  end

  def from_motherboard_get_entity(motherboard_id) do
    CacheInternal.lookup({:motherboard, :entity}, [motherboard_id])
  end

  def from_motherboard_get_resources(motherboard_id) do
    CacheInternal.lookup({:motherboard, :resources}, [motherboard_id])
  end

  def from_motherboard_get_components(motherboard_id) do
    CacheInternal.lookup({:motherboard, :components}, [motherboard_id])
  end

  def from_entity_get_motherboard(entity_id) do
    CacheInternal.lookup({:entity, :motherboard}, [entity_id])
  end

  def from_storage_get_server(storage_id) do
    CacheInternal.lookup({:storage, :server}, [storage_id])
  end

  def from_nip_get_server(network_id, ip) do
    CacheInternal.lookup({:nip, :server}, [network_id, ip])
  end

  def from_component_get_motherboard(component_id) do
    CacheInternal.lookup({:component, :motherboard}, [component_id])
  end
end
