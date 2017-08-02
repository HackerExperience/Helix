defmodule Helix.Cache.Integration.Software.StorageDriveTest do

  use Helix.Test.IntegrationCase

  alias Helix.Hardware.Internal.Motherboard, as: MotherboardInternal
  alias Helix.Software.Internal.Storage, as: StorageInternal
  alias Helix.Software.Internal.StorageDrive, as: StorageDriveInternal
  alias Helix.Cache.Action.Cache, as: CacheAction
  alias Helix.Cache.Internal.Builder, as: BuilderInternal
  alias Helix.Cache.Internal.Cache, as: CacheInternal
  alias Helix.Cache.Internal.Populate, as: PopulateInternal
  alias Helix.Cache.State.PurgeQueue, as: StatePurgeQueue

  alias Helix.Cache.Helper, as: CacheHelper
  alias Helix.Hardware.Factory, as: HardwareFactory

  setup do
    CacheHelper.cache_context()
  end

  describe "link storage to drive" do
    test "it updates the cache", context do
      server_id = context.server.server_id
      motherboard_id = context.server.motherboard_id

      # Populate on the DB
      {:ok, server} = PopulateInternal.populate(:by_server, server_id)
      assert {:hit, _} = CacheInternal.direct_query(:server, server_id)

      # Integration stuff
      hdd = HardwareFactory.insert(:hdd)
      drive_id = hdd.component.component_id

      slot = motherboard_id
        |> MotherboardInternal.get_slots()
        |> Enum.find(fn(slot) ->
          slot.link_component_id == nil and slot.link_component_type == :hdd
        end)

      assert {:ok, _} = MotherboardInternal.link(slot, hdd.component)

      storage_id = Enum.random(server.storages)

      storage = StorageInternal.fetch(storage_id)
      refute is_nil(storage)

      StatePurgeQueue.sync()

      refute StatePurgeQueue.lookup(:storage, storage_id)
      refute StatePurgeQueue.lookup(:server, server_id)

      # Link!
      assert :ok == StorageDriveInternal.link_drive(storage, drive_id)

      # Added to purge queue
      assert StatePurgeQueue.lookup(:server, server_id)
      assert StatePurgeQueue.lookup(:storage, storage_id)
      assert StatePurgeQueue.lookup(:component, Enum.random(server.components))

      StatePurgeQueue.sync()

      # Properly updated
      assert {:ok, server} = CacheInternal.lookup(:server, server_id)
      assert server.expiration_date
      assert Enum.find(server.storages, &(&1 == storage_id))
    end

    test "it updates the cache (cold)", context do
      server_id = context.server.server_id
      motherboard_id = context.server.motherboard_id

      # Note: Cold testing here is a bit trickier because calling functions like
      # `MotherboardInternal.link` will themselves populate the cache.
      # So here we'll take a dirty approach: Get all the data we need without
      # caring about cache. Then, directly purge the server. And then do the test.

      {:ok, server} = BuilderInternal.by_server(server_id)

      # Integration stuff
      hdd = HardwareFactory.insert(:hdd)
      drive_id = hdd.component.component_id

      slot = motherboard_id
      |> MotherboardInternal.get_slots()
      |> Enum.find(fn(slot) ->
        slot.link_component_id == nil and slot.link_component_type == :hdd
      end)

      assert {:ok, _} = MotherboardInternal.link(slot, hdd.component)

      storage_id = Enum.random(server.storages)

      storage = StorageInternal.fetch(storage_id)
      refute is_nil(storage)

      StatePurgeQueue.sync()

      # Empty the cache
      CacheAction.purge_server(server_id)

      StatePurgeQueue.sync()

      # Ensure cache is empty
      refute StatePurgeQueue.lookup(:storage, storage_id)
      refute StatePurgeQueue.lookup(:server, server_id)
      assert :miss == CacheInternal.direct_query(:server, server_id)

      # Now we'll link the storage

      assert :ok == StorageDriveInternal.link_drive(storage, drive_id)

      # Aaaand nothing is added to the PurgeQueue!
      refute StatePurgeQueue.lookup(:storage, storage_id)
      refute StatePurgeQueue.lookup(:server, server_id)

      StatePurgeQueue.sync()

      assert :miss == CacheInternal.direct_query(:server, server_id)
    end
  end

  describe "unlink storage from drive" do
    test "it updates the cache", context do
      server_id = context.server.server_id
      motherboard_id = context.server.motherboard_id

      # Populate on the DB
      {:ok, server} = PopulateInternal.populate(:by_server, server_id)
      assert {:hit, _} = CacheInternal.direct_query(:server, server_id)

      storage_id = List.first(server.storages)

      [hdd] = MotherboardInternal.get_hdds(motherboard_id)
      drive_id = hdd.hdd_id

      StorageDriveInternal.unlink_drive(drive_id)

      assert StatePurgeQueue.lookup(:server, server_id)
      assert StatePurgeQueue.lookup(:storage, storage_id)
      assert StatePurgeQueue.lookup(:component, motherboard_id)

      StatePurgeQueue.sync()

      assert :miss == CacheInternal.direct_query(:storage, storage_id)
      assert {:hit, server2} = CacheInternal.direct_query(:server, server_id)

      refute Enum.find(server2.storages, &(&1 == storage_id))
    end

    test "it updates the cache (cold)", context do
      server_id = context.server.server_id
      motherboard_id = context.server.motherboard_id

      {:ok, server} = BuilderInternal.by_server(server_id)

      storage_id = List.first(server.storages)

      [hdd] = MotherboardInternal.get_hdds(motherboard_id)
      drive_id = hdd.hdd_id

      StorageDriveInternal.unlink_drive(drive_id)

      assert StatePurgeQueue.lookup(:storage, storage_id)
      refute StatePurgeQueue.lookup(:server, server_id)
      refute StatePurgeQueue.lookup(:component, motherboard_id)

      StatePurgeQueue.sync()

      assert :miss == CacheInternal.direct_query(:storage, storage_id)
      assert :miss == CacheInternal.direct_query(:server, server_id)
    end
  end
end

