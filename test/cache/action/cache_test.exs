defmodule Helix.Cache.Action.CacheTest do

  use Helix.Test.IntegrationCase

  alias Helix.Cache.Action.Cache, as: CacheAction
  alias Helix.Cache.Internal.Cache, as: CacheInternal
  alias Helix.Cache.Internal.Populate, as: PopulateInternal
  alias Helix.Cache.State.PurgeQueue, as: StatePurgeQueue

  setup do
    alias Helix.Account.Factory, as: AccountFactory
    alias Helix.Account.Action.Flow.Account, as: AccountFlow

    account = AccountFactory.insert(:account)
    {:ok, %{server: server}} = AccountFlow.setup_account(account)

    {:ok, account: account, server: server}
  end

  def hit_everything(server_id) do
    {:hit, server1} = CacheInternal.direct_query(:server, server_id)

    storage1_id = List.first(server1.storages)
    {:hit, storage1} = CacheInternal.direct_query(:storage, storage1_id)

    component1_id = List.first(server1.components)
    {:hit, component1} = CacheInternal.direct_query(:component, component1_id)

    {:hit, motherboard1} = CacheInternal.direct_query(:component, server1.motherboard_id)

    net1 = List.first(server1.networks)
    {:hit, nip1} = CacheInternal.direct_query(:network, {net1.network_id, net1.ip})

    {server1, storage1, component1, motherboard1, nip1}
  end

  def assert_expiration_updated(data1, data2) do
    assert data1.expiration_date != data2.expiration_date
  end

  describe "update logic" do
    test "update_server/1", context do
      server_id = context.server.server_id

      PopulateInternal.populate(:by_server, server_id)

      # Sync (wait for side-population)
      :timer.sleep(20)

      {server1, storage1, component1, mobo1, nip1} = hit_everything(server_id)

      # Update
      CacheAction.update_server(server_id)

      # Sync (wait for side-population)
      :timer.sleep(20)

      {server2, storage2, component2, mobo2, nip2} = hit_everything(server_id)

      assert_expiration_updated(server1, server2)
      assert_expiration_updated(storage1, storage2)
      assert_expiration_updated(component1, component2)
      assert_expiration_updated(mobo1, mobo2)
      assert_expiration_updated(nip1, nip2)

      :timer.sleep(10)
    end

    test "update_storage/1", context do
      server_id = context.server.server_id

      PopulateInternal.populate(:by_server, server_id)

      # Sync (wait for side-population)
      :timer.sleep(20)

      {server1, storage1, component1, mobo1, nip1} = hit_everything(server_id)

      storage_id = List.first(server1.storages)
      CacheAction.update_storage(storage_id)

      # Sync (wait for side-population)
      :timer.sleep(20)

      {server2, storage2, component2, mobo2, nip2} = hit_everything(server_id)

      assert_expiration_updated(server1, server2)
      assert_expiration_updated(storage1, storage2)
      assert_expiration_updated(component1, component2)
      assert_expiration_updated(mobo1, mobo2)
      assert_expiration_updated(nip1, nip2)

      :timer.sleep(10)
    end

    test "update_component/1", context do
      server_id = context.server.server_id

      PopulateInternal.populate(:by_server, server_id)

      # Sync (wait for side-population)
      :timer.sleep(20)

      {server1, storage1, component1, mobo1, nip1} = hit_everything(server_id)

      component_id = List.first(server1.components)
      CacheAction.update_component(component_id)

      # Sync (wait for side-population)
      :timer.sleep(20)

      {server2, storage2, component2, mobo2, nip2} = hit_everything(server_id)

      assert_expiration_updated(server1, server2)
      assert_expiration_updated(storage1, storage2)
      assert_expiration_updated(component1, component2)
      assert_expiration_updated(mobo1, mobo2)
      assert_expiration_updated(nip1, nip2)

      :timer.sleep(10)
    end

    test "update_nip/1", context do
      server_id = context.server.server_id

      PopulateInternal.populate(:by_server, server_id)

      # Sync (wait for side-population)
      :timer.sleep(20)

      {server1, storage1, component1, mobo1, nip1} = hit_everything(server_id)

      net = List.first(server1.networks)
      CacheAction.update_nip(net.network_id, net.ip)

      # Sync (wait for side-population)
      :timer.sleep(20)

      {server2, storage2, component2, mobo2, nip2} = hit_everything(server_id)

      assert_expiration_updated(server1, server2)
      assert_expiration_updated(storage1, storage2)
      assert_expiration_updated(component1, component2)
      assert_expiration_updated(mobo1, mobo2)
      assert_expiration_updated(nip1, nip2)

      :timer.sleep(10)
    end

    # test "purge_motherboard/1", context do
    #   server_id = context.server.server_id
    #   motherboard_id = context.server.motherboard_id

    #   PopulateInternal.populate(:by_server, server_id)
    #   :timer.sleep(20)

    #   {:ok, server} = CacheInternal.lookup(:motherboard, [motherboard_id])

    #   refute StatePurgeQueue.lookup(:component, motherboard_id)

    #   # Purge it
    #   CacheAction.purge_motherboard(motherboard_id)

    #   # Ensure mobo component is marked as purged
    #   assert StatePurgeQueue.lookup(:component, motherboard_id)

    #   # As well as all components that could be linked to that mobo
    #   Enum.each(server.components, fn(component) ->
    #     assert StatePurgeQueue.lookup(:component, component)
    #   end)

    #   # And the server too (which will soon be updated)
    #   assert StatePurgeQueue.lookup(:server, server.server_id)

    #   # Note that the purged motherboard will soon be re-added to the DB
    #   # because it is still linked to server, and calling `purge_motherboard`
    #   # will call `CacheAction.update_server`, which will re-fetch the mobo.

    #   :timer.sleep(100)
    # end
  end
end
