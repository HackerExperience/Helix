defmodule Helix.Cache.Internal.Purge do
  @moduledoc """
  `PurgeInternal` is responsible for handling cache invalidation.

  The API user may choose to either update or delete an object.

  Updates are quite dumb: we'll always update *all* elements related to the
  object that was requested to be updated, overwriting any existing entries
  without prior verification.

  Deletes are also dumb, and they do not interact with other objects. Requesting
  deletion of, say, storage won't lead to deletion of related servers.

  To know which one you should use, check the CacheAction API.
  """

  alias Helix.Cache.Model.ComponentCache
  alias Helix.Cache.Model.NetworkCache
  alias Helix.Cache.Model.StorageCache
  alias Helix.Cache.Internal.Cache, as: CacheInternal
  alias Helix.Cache.Internal.Populate, as: PopulateInternal
  alias Helix.Cache.Repo

  def update(:server, server_id) do
    PopulateInternal.populate(:server, server_id)
  end
  def update(model, _) do
    raise "update not implemented for #{inspect model}"
  end

  def purge(:component, component_id) do
    delete(:component, component_id)
  end
  def purge(:storage, storage_id) do
    delete(:storage, storage_id)
  end
  def purge(:network, network_id, ip) do
    delete(:network, network_id, ip)
  end

  def delete(:component, component_id) do
    ComponentCache.Query.by_component(component_id)
    |> Repo.delete_all()

    CacheInternal.remove_from_purge_queue(:component, component_id)
  end
  def delete(:storage, storage_id) do
    StorageCache.Query.by_storage(storage_id)
    |> Repo.delete_all()

    CacheInternal.remove_from_purge_queue(:storage, storage_id)
  end
  def delete(:network, network_id, ip) do
    NetworkCache.Query.by_nip(network_id, ip)
    |> Repo.delete_all()

    CacheInternal.remove_from_purge_queue(:network, [network_id, ip])
  end
end
