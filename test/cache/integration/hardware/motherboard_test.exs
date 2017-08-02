defmodule Helix.Cache.Integration.Hardware.MotherboardTest do

  use Helix.Test.IntegrationCase

  alias Helix.Hardware.Factory, as: HardwareFactory
  alias Helix.Hardware.Internal.Motherboard, as: MotherboardInternal
  alias Helix.Cache.Helper, as: CacheHelper
  alias Helix.Cache.Internal.Builder, as: BuilderInternal
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
      assert StatePurgeQueue.lookup(:server, server_id)

      CacheHelper.sync_test()
    end

    test "motherboard deletion (cold)", context do
      server_id = context.server.server_id
      motherboard_id = context.server.motherboard_id

      MotherboardInternal.delete(motherboard_id)

      assert StatePurgeQueue.lookup(:component, motherboard_id)

      # Server won't be updated because there's no need for it
      refute StatePurgeQueue.lookup(:server, server_id)

      CacheHelper.sync_test()
    end

    test "unlink component from mobo", context do
      server_id = context.server.server_id
      motherboard_id = context.server.motherboard_id

      {:ok, server} = PopulateInternal.populate(:by_server, server_id)

      nip = Enum.random(server.networks)

      component_id = Enum.random(server.components)
      slots = MotherboardInternal.get_slots(motherboard_id)
      slot = Enum.find(slots, &(&1.link_component_id == component_id))

      refute StatePurgeQueue.lookup(:server, server_id)

      MotherboardInternal.unlink(slot)

      assert StatePurgeQueue.lookup(:server, server_id)
      assert StatePurgeQueue.lookup(:component, component_id)
      assert StatePurgeQueue.lookup(:component, motherboard_id)
      assert StatePurgeQueue.lookup(:component, List.last(server.components))
      assert StatePurgeQueue.lookup(:storage, Enum.random(server.storages))
      assert StatePurgeQueue.lookup(:network, {nip.network_id, nip.ip})

      CacheHelper.sync_test()
    end

    test "unlink component from mobo (cold)", context do
      server_id = context.server.server_id
      motherboard_id = context.server.motherboard_id

      alias Helix.Cache.Internal.Builder, as: BuilderInternal
      {:ok, server} = BuilderInternal.by_server(server_id)

      nip = Enum.random(server.networks)

      component_id = List.first(server.components)
      slots = MotherboardInternal.get_slots(motherboard_id)
      slot = Enum.find(slots, &(&1.link_component_id == component_id))

      refute StatePurgeQueue.lookup(:server, server_id)

      MotherboardInternal.unlink(slot)

      assert StatePurgeQueue.lookup(:component, component_id)
      assert StatePurgeQueue.lookup(:component, motherboard_id)

      # No need to purge server
      refute StatePurgeQueue.lookup(:server, server_id)
      refute StatePurgeQueue.lookup(:component, List.last(server.components))
      refute StatePurgeQueue.lookup(:storage, Enum.random(server.storages))
      refute StatePurgeQueue.lookup(:network, {nip.network_id, nip.ip})

      CacheHelper.sync_test()
    end

    test "unlink all", context do
      server_id = context.server.server_id
      motherboard_id = context.server.motherboard_id

      {:ok, server} = PopulateInternal.populate(:by_server, server_id)

      nip = Enum.random(server.networks)

      refute StatePurgeQueue.lookup(:server, server_id)

      MotherboardInternal.unlink_components_from_motherboard(motherboard_id)

      assert StatePurgeQueue.lookup(:component, motherboard_id)
      Enum.map(server.components, fn(component_id) ->
        assert StatePurgeQueue.lookup(:component, component_id)
      end)
      assert StatePurgeQueue.lookup(:server, server_id)
      assert StatePurgeQueue.lookup(:storage, Enum.random(server.storages))
      assert StatePurgeQueue.lookup(:network, {nip.network_id, nip.ip})

      CacheHelper.sync_test()
    end

    test "unlink all (cold)", context do
      server_id = context.server.server_id
      motherboard_id = context.server.motherboard_id

      {:ok, server} = BuilderInternal.by_server(server_id)

      nip = Enum.random(server.networks)

      refute StatePurgeQueue.lookup(:server, server_id)

      MotherboardInternal.unlink_components_from_motherboard(motherboard_id)

      assert StatePurgeQueue.lookup(:component, motherboard_id)
      Enum.map(server.components, fn(component_id) ->
        assert StatePurgeQueue.lookup(:component, component_id)
      end)
      refute StatePurgeQueue.lookup(:server, server_id)
      refute StatePurgeQueue.lookup(:storage, Enum.random(server.storages))
      refute StatePurgeQueue.lookup(:network, {nip.network_id, nip.ip})

      CacheHelper.sync_test()
    end

    # Note: the tests below are quite similar but they do go through different
    # paths, specially at the BuilderInternal, so do not remove any of them
    test "link hdd to mobo", context do
      server_id = context.server.server_id
      motherboard_id = context.server.motherboard_id

      {:ok, server} = PopulateInternal.populate(:by_server, server_id)

      nip = Enum.random(server.networks)

      slot = motherboard_id
        |> MotherboardInternal.get_slots()
        |> Enum.find(fn(slot) ->
            slot.link_component_id == nil and slot.link_component_type == :hdd
          end)

      refute StatePurgeQueue.lookup(:server, server_id)

      hdd = HardwareFactory.insert(:hdd)

      assert {:ok, _} = MotherboardInternal.link(slot, hdd.component)

      assert StatePurgeQueue.lookup(:component, hdd.component.component_id)
      assert StatePurgeQueue.lookup(:server, server_id)
      assert StatePurgeQueue.lookup(:component, motherboard_id)
      assert StatePurgeQueue.lookup(:component, Enum.random(server.components))
      assert StatePurgeQueue.lookup(:storage, Enum.random(server.storages))
      assert StatePurgeQueue.lookup(:network, {nip.network_id, nip.ip})

      CacheHelper.sync_test()
    end

    test "link hdd to mobo (cold)", context do
      server_id = context.server.server_id
      motherboard_id = context.server.motherboard_id

      {:ok, server} = BuilderInternal.by_server(server_id)

      nip = Enum.random(server.networks)

      slot = motherboard_id
        |> MotherboardInternal.get_slots()
        |> Enum.find(fn(slot) ->
          slot.link_component_id == nil and slot.link_component_type == :hdd
        end)

      refute StatePurgeQueue.lookup(:server, server_id)

      hdd = HardwareFactory.insert(:hdd)

      assert {:ok, _} = MotherboardInternal.link(slot, hdd.component)

      assert StatePurgeQueue.lookup(:component, hdd.component.component_id)
      assert StatePurgeQueue.lookup(:component, motherboard_id)
      refute StatePurgeQueue.lookup(:server, server_id)
      refute StatePurgeQueue.lookup(:component, Enum.random(server.components))
      refute StatePurgeQueue.lookup(:storage, Enum.random(server.storages))
      refute StatePurgeQueue.lookup(:network, {nip.network_id, nip.ip})

      CacheHelper.sync_test()
    end

    test "link nic to mobo", context do
      server_id = context.server.server_id
      motherboard_id = context.server.motherboard_id

      {:ok, server} = PopulateInternal.populate(:by_server, server_id)

      nip = Enum.random(server.networks)

      slot = motherboard_id
      |> MotherboardInternal.get_slots()
      |> Enum.find(fn(slot) ->
        slot.link_component_id == nil and slot.link_component_type == :nic
      end)

      refute StatePurgeQueue.lookup(:server, server_id)

      nic = HardwareFactory.insert(:nic)

      assert {:ok, _} = MotherboardInternal.link(slot, nic.component)

      assert StatePurgeQueue.lookup(:server, server_id)
      assert StatePurgeQueue.lookup(:component, motherboard_id)
      assert StatePurgeQueue.lookup(:component, List.last(server.components))
      assert StatePurgeQueue.lookup(:storage, Enum.random(server.storages))
      assert StatePurgeQueue.lookup(:network, {nip.network_id, nip.ip})

      CacheHelper.sync_test()
    end

    test "link nic to mobo (cold)", context do
      server_id = context.server.server_id
      motherboard_id = context.server.motherboard_id

      {:ok, server} = BuilderInternal.by_server(server_id)

      nip = Enum.random(server.networks)

      slot = motherboard_id
      |> MotherboardInternal.get_slots()
      |> Enum.find(fn(slot) ->
        slot.link_component_id == nil and slot.link_component_type == :nic
      end)

      refute StatePurgeQueue.lookup(:server, server_id)

      nic = HardwareFactory.insert(:nic)

      assert {:ok, _} = MotherboardInternal.link(slot, nic.component)

      assert StatePurgeQueue.lookup(:component, nic.component.component_id)
      assert StatePurgeQueue.lookup(:component, motherboard_id)
      refute StatePurgeQueue.lookup(:server, server_id)
      refute StatePurgeQueue.lookup(:component, List.last(server.components))
      refute StatePurgeQueue.lookup(:storage, Enum.random(server.storages))
      refute StatePurgeQueue.lookup(:network, {nip.network_id, nip.ip})

      CacheHelper.sync_test()
    end

  end
end
