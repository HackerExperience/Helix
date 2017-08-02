defmodule Helix.Cache.Helper do

  alias Helix.Account.Action.Flow.Account, as: AccountFlow
  alias Helix.Account.Factory, as: AccountFactory
  alias Helix.Cache.Action.Cache, as: CacheAction
  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Cache.State.PurgeQueue, as: StatePurgeQueue
  alias Helix.Cache.Internal.Cache, as: CacheInternal

  def sync_test,
    do: StatePurgeQueue.sync()

  def cache_context do
    account = AccountFactory.insert(:account)
    {:ok, %{server: server}} = AccountFlow.setup_account(account)
    :timer.sleep(100)

    # Note: for our purposes, function below is slightly different from
    # CacheInternal.purge_server, and should not be replaced.
    purge_server(server.server_id)

    {:ok, account: account, server: server}
  end

  def purge_server(server_id) do
    {:ok, server} = CacheQuery.from_server_get_all(server_id)

    StatePurgeQueue.sync()

    Enum.each(server.networks, &CacheAction.purge_nip(&1.network_id, &1.ip))
    Enum.each(server.components, &CacheAction.purge_component(&1))
    Enum.each(server.storages, &CacheAction.purge_storage(&1))
    CacheAction.purge_component(server.motherboard_id)

    StatePurgeQueue.queue(:server, server.server_id, :purge)
    CacheInternal.purge(:server, {server.server_id})

    StatePurgeQueue.sync()
  end
end
