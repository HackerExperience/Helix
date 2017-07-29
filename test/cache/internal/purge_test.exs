defmodule Helix.Cache.Internal.PurgeTest do

  use Helix.Test.IntegrationCase

  alias Helix.Hardware.Internal.NetworkConnection, as: NetworkConnectionInternal
  alias Helix.Cache.Internal.Cache, as: CacheInternal
  alias Helix.Cache.Internal.Populate, as: PopulateInternal
  alias Helix.Cache.Internal.Purge, as: PurgeInternal
  alias Helix.Cache.State.PurgeQueue, as: StatePurgeQueue

  setup do
    alias Helix.Account.Factory, as: AccountFactory
    alias Helix.Account.Action.Flow.Account, as: AccountFlow

    account = AccountFactory.insert(:account)
    {:ok, %{server: server}} = AccountFlow.setup_account(account)

    :timer.sleep(50)

    alias Helix.Cache.Action.Cache, as: CacheAction
    CacheAction.purge_server(server.server_id)
    :timer.sleep(50)

    {:ok, account: account, server: server}
  end

  # REMEMBER:
  # - PurgeInternal.update|purge is SYNCHRONOUS
  #   - (but side-population isn't)
  # - CacheInternal.update|purge is ASYNCHRONOUS
  #   - (but mark_as_purged/2 isn't)

  describe "update/2" do
    test "existing data is updated", context do
      server_id = context.server.server_id

      # Add server server
      {:ok, _} = PopulateInternal.populate(:by_server, server_id)
      :timer.sleep(10)

      {:hit, server1} = CacheInternal.direct_query(:server, server_id)

      # Modify server
      nip = List.first(server1.networks)
      nc = NetworkConnectionInternal.fetch_by_nip("::", nip.ip)
      new_ip = HELL.IPv4.autogenerate()
      {:ok, _} = NetworkConnectionInternal.update_ip(nc, new_ip)

      :timer.sleep(20)

      # Query again
      {:ok, server2} = CacheInternal.lookup(:server, server_id)

      server2_ip = server2.networks
        |> List.first()
        |> Map.get(:ip)

      :miss = CacheInternal.direct_query(:network, {nip.network_id, nip.ip})

      assert server1 != server2
      assert server1.server_id == server2.server_id
      refute nip.ip == server2_ip
      assert server2_ip == new_ip

      :timer.sleep(10)
    end

    test "populates non-existing data", context  do
      server_id = context.server.server_id

      :timer.sleep(100)
      :miss = CacheInternal.direct_query(:server, server_id)

      refute StatePurgeQueue.lookup(:server, server_id)

      # Request server update
      CacheInternal.update(:server, server_id)

      # It's added to the queue
      assert StatePurgeQueue.lookup(:server, server_id)

      # But hasn't synced yet
      :miss = CacheInternal.direct_query(:server, server_id)
      :miss = CacheInternal.direct_query(:server, server_id)
      :miss = CacheInternal.direct_query(:server, server_id)

      # TODO: PurgeQueue.sync
      :timer.sleep(30)

      refute StatePurgeQueue.lookup(:server, server_id)

      {:hit, server} = CacheInternal.direct_query(:server, server_id)

      assert server.server_id == server_id

      :timer.sleep(10)
    end
  end

  describe "purge/2" do
    test "obliterates objects from DB", context do
      server_id = context.server.server_id

      {:ok, server} = PopulateInternal.populate(:by_server, server_id)
      :timer.sleep(20)
      nip = List.first(server.networks)
      storage_id = List.first(server.storages)
      component_id = List.first(server.components)
      motherboard_id = server.motherboard_id

      # Purge nip
      PurgeInternal.purge(:network, {nip.network_id, nip.ip})

      # (PurgeInternal.purge is synchronous)

      :miss = CacheInternal.direct_query(:network, {nip.network_id, nip.ip})

      # Purging nip shouldn't affect others
      {:hit, _} = CacheInternal.direct_query(:component, component_id)
      {:hit, _} = CacheInternal.direct_query(:component, motherboard_id)
      {:hit, _} = CacheInternal.direct_query(:storage, storage_id)
      {:hit, _} = CacheInternal.direct_query(:server, server_id)

      # Purging storage
      PurgeInternal.purge(:storage, {storage_id})

      :miss = CacheInternal.direct_query(:storage, storage_id)

      # Purging storage shouldn't affect others
      {:hit, _} = CacheInternal.direct_query(:component, component_id)
      {:hit, _} = CacheInternal.direct_query(:component, motherboard_id)
      {:hit, _} = CacheInternal.direct_query(:server, server_id)

      # Purging component
      PurgeInternal.purge(:component, {component_id})

      :miss = CacheInternal.direct_query(:component, component_id)

      # Purging a component shouldn't affect others
      {:hit, _} = CacheInternal.direct_query(:component, motherboard_id)
      {:hit, _} = CacheInternal.direct_query(:server, server_id)

      # Purge motherboard
      PurgeInternal.purge(:component, {motherboard_id})

      :miss = CacheInternal.direct_query(:component, motherboard_id)

      # Server is still there
      {:hit, _} = CacheInternal.direct_query(:server, server_id)

      :timer.sleep(10)
    end
  end
end
