defmodule Helix.Test.Cache.Helper do

  alias Helix.Cache.Action.Cache, as: CacheAction
  alias Helix.Cache.Internal.Cache, as: CacheInternal
  alias Helix.Cache.Model.ServerCache
  alias Helix.Cache.Model.NetworkCache
  alias Helix.Cache.Model.StorageCache
  alias Helix.Cache.Model.ComponentCache
  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Cache.Repo
  alias Helix.Cache.State.PurgeQueue, as: StatePurgeQueue

  alias Helix.Test.Server.Setup, as: ServerSetup

  def sync_test,
    do: StatePurgeQueue.sync()

  def cache_context do
    {server, _entity} = ServerSetup.server()

    {:ok, server: server}
  end

  def purge_server(server_id) do
    {:ok, server} = CacheQuery.from_server_get_all(server_id)
    StatePurgeQueue.sync()

    Enum.each(
      server.networks,
      &CacheAction.purge_network(to_string(&1.network_id), &1.ip))
    Enum.each(server.components, &CacheAction.purge_component(to_string(&1)))
    Enum.each(server.storages, &CacheAction.purge_storage(to_string(&1)))
    CacheAction.purge_component(to_string(server.motherboard_id))

    StatePurgeQueue.queue(:server, to_string(server.server_id), :purge)
    CacheInternal.purge(:server, {to_string(server.server_id)})

    StatePurgeQueue.sync()
  end

  def empty_cache do
    Repo.delete_all(ServerCache)
    Repo.delete_all(ComponentCache)
    Repo.delete_all(StorageCache)
    Repo.delete_all(NetworkCache)
  end
end
