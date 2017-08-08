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

  Remember:
  - PurgeInternal.update/purge is SYNCHRONOUS (but side-population isn't)
  - CacheInternal.update/purge is ASYNCHRONOUS (but adding to queue isn't)
  """

  alias Helix.Cache.Model.ServerCache
  alias Helix.Cache.Model.ComponentCache
  alias Helix.Cache.Model.NetworkCache
  alias Helix.Cache.Model.StorageCache
  alias Helix.Cache.Model.WebCache
  alias Helix.Cache.Internal.Populate, as: PopulateInternal
  alias Helix.Cache.Repo

  @doc """
  Given a model and an identifier, updates the cache.

  It must always be called by StatePurgeQueue, during the synchronization step.

  Our update logic is as dumb as possible: always modify the database, even if
  no such entry exists. Essentially, it performs a UPSERT. As such, we delegate
  the whole `update` implementation to `PopulateInternal.populate`.
  """
  def update(:server, object),
    do: PopulateInternal.populate(:by_server, object)
  def update(:storage, object),
    do: PopulateInternal.populate(:by_storage, object)
  def update(:component, object),
    do: PopulateInternal.populate(:by_component, object)
  def update(:network, object),
    do: PopulateInternal.populate(:by_nip, object)
  def update(:web, object),
    do: PopulateInternal.populate(:web_by_nip, object)
  def update(model, _),
    do: raise "update not implemented for #{inspect model}"

  @doc """
  Given a model and an identifier, purges the cache.

  It must always be called by StatePurgeQueue, during the synchronization step.

  The purge logic is as dumb as it can be: attempt to delete regardless if there
  actually is something on the DB. It also won't bother purging related data.
  Purging/updating related data is done at higher levels, mainly at the
  CacheAction API.
  """
  def purge(:server, object),
    do: delete(:server, object)
  def purge(:component, object),
    do: delete(:component, object)
  def purge(:storage, object),
    do: delete(:storage, object)
  def purge(:network, object),
    do: delete(:network, object)
  def purge(:web, object),
    do: delete(:web, object)
  def purge(model, _),
    do: raise "purge not implemented for #{inspect model}"

  defp delete(:server, {server_id}) do
    ServerCache.Query.by_server(server_id)
    |> Repo.delete_all()
  end
  defp delete(:component, {component_id}) do
    ComponentCache.Query.by_component(component_id)
    |> Repo.delete_all()
  end
  defp delete(:storage, {storage_id}) do
    StorageCache.Query.by_storage(storage_id)
    |> Repo.delete_all()
  end
  defp delete(:network, {network_id, ip}) do
    NetworkCache.Query.by_nip(network_id, ip)
    |> Repo.delete_all()
  end
  defp delete(:web, {network_id, ip}) do
    WebCache.Query.web_by_nip(network_id, ip)
    |> Repo.delete_all()
  end
end
