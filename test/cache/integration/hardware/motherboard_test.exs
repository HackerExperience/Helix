defmodule Helix.Cache.Integration.Hardware.MotherboardTest do

  use Helix.Test.IntegrationCase

  alias Helix.Hardware.Factory, as: HardwareFactory
  alias Helix.Hardware.Internal.Motherboard, as: MotherboardInternal
  alias Helix.Cache.Helper, as: CacheHelper
  alias Helix.Cache.Internal.Populate, as: PopulateInternal
  alias Helix.Cache.State.PurgeQueue, as: StatePurgeQueue

  setup do
    CacheHelper.cache_context()
  end

  describe "motherboard integration" do
    test "motherboard deletion", context do
      server_id = context.server.server_id
      motherboard_id = context.server.motherboard_id

      {:ok, _} = PopulateInternal.populate(:by_server, server_id)

      MotherboardInternal.delete(motherboard_id)

      assert StatePurgeQueue.lookup(:component, motherboard_id)

      # Note that it only deletes the motherboard, not the server entry.
      # It's not a problem as long as the proper APIs are used!
      refute StatePurgeQueue.lookup(:server, server_id)

      CacheHelper.sync_test()
    end

    test "unlink component from mobo", context do
      server_id = context.server.server_id
      motherboard_id = context.server.motherboard_id

      {:ok, server} = PopulateInternal.populate(:by_server, server_id)

      nip = List.first(server.networks)

      component_id = List.first(server.components)
      slots = MotherboardInternal.get_slots(motherboard_id)
      slot = Enum.find(slots, &(&1.link_component_id == component_id))

      refute StatePurgeQueue.lookup(:server, server_id)

      MotherboardInternal.unlink(slot)

      assert StatePurgeQueue.lookup(:server, server_id)
      assert StatePurgeQueue.lookup(:component, component_id)
      assert StatePurgeQueue.lookup(:component, motherboard_id)
      assert StatePurgeQueue.lookup(:component, List.last(server.components))
      assert StatePurgeQueue.lookup(:storage, List.first(server.storages))
      assert StatePurgeQueue.lookup(:network, {nip.network_id, nip.ip})

      CacheHelper.sync_test()
    end

    test "unlink all", context do
      server_id = context.server.server_id
      motherboard_id = context.server.motherboard_id

      {:ok, server} = PopulateInternal.populate(:by_server, server_id)

      nip = List.first(server.networks)

      refute StatePurgeQueue.lookup(:server, server_id)

      MotherboardInternal.unlink_components_from_motherboard(motherboard_id)

      assert StatePurgeQueue.lookup(:server, server_id)
      assert StatePurgeQueue.lookup(:component, motherboard_id)
      Enum.map(server.components, fn(component_id) ->
        assert StatePurgeQueue.lookup(:component, component_id)
      end)

      # Note that unlinking all won't update storage and network. That's
      # because, without a proper mobo, the Builder won't be able to build
      # a valid cache entry. That's not a problem.... as long as the proper
      # APIs are used!!!11!
      refute StatePurgeQueue.lookup(:storage, List.first(server.storages))
      refute StatePurgeQueue.lookup(:network, {nip.network_id, nip.ip})

      CacheHelper.sync_test()
    end

    # Note: the tests below are quite similar but they do go through different
    # paths, specially at the BuilderInternal, so do not remove any of them
    test "link hdd to mobo", context do
      server_id = context.server.server_id
      motherboard_id = context.server.motherboard_id

      {:ok, server} = PopulateInternal.populate(:by_server, server_id)

      nip = List.first(server.networks)

      component_id = List.first(server.components)
      slots = MotherboardInternal.get_slots(motherboard_id)

      slot = Enum.find(slots, fn(slot) ->
        slot.link_component_id == nil and slot.link_component_type == :hdd
      end)

      refute StatePurgeQueue.lookup(:server, server_id)

      hdd = HardwareFactory.insert(:hdd)

      assert {:ok, _} = MotherboardInternal.link(slot, hdd.component)

      assert StatePurgeQueue.lookup(:server, server_id)
      assert StatePurgeQueue.lookup(:component, component_id)
      assert StatePurgeQueue.lookup(:component, motherboard_id)
      assert StatePurgeQueue.lookup(:component, List.last(server.components))
      assert StatePurgeQueue.lookup(:storage, List.first(server.storages))
      assert StatePurgeQueue.lookup(:network, {nip.network_id, nip.ip})

      CacheHelper.sync_test()
    end

    test "link nic to mobo", context do
      server_id = context.server.server_id
      motherboard_id = context.server.motherboard_id

      {:ok, server} = PopulateInternal.populate(:by_server, server_id)

      nip = List.first(server.networks)

      component_id = List.first(server.components)
      slots = MotherboardInternal.get_slots(motherboard_id)

      slot = Enum.find(slots, fn(slot) ->
        slot.link_component_id == nil and slot.link_component_type == :nic
      end)

      refute StatePurgeQueue.lookup(:server, server_id)

      nic = HardwareFactory.insert(:nic)

      assert {:ok, _} = MotherboardInternal.link(slot, nic.component)

      assert StatePurgeQueue.lookup(:server, server_id)
      assert StatePurgeQueue.lookup(:component, component_id)
      assert StatePurgeQueue.lookup(:component, motherboard_id)
      assert StatePurgeQueue.lookup(:component, List.last(server.components))
      assert StatePurgeQueue.lookup(:storage, List.first(server.storages))
      assert StatePurgeQueue.lookup(:network, {nip.network_id, nip.ip})

      CacheHelper.sync_test()
    end
  end
end
