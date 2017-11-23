defmodule Helix.Cache.Internal.BuilderTest do

  use Helix.Test.Case.Integration

  import Helix.Test.Case.ID

  alias HELL.TestHelper.Random
  alias Helix.Server.Internal.Motherboard, as: MotherboardInternal
  alias Helix.Server.Internal.Server, as: ServerInternal
  alias Helix.Software.Internal.StorageDrive, as: StorageDriveInternal
  alias Helix.Software.Model.Storage
  alias Helix.Universe.NPC.Model.Seed
  alias Helix.Test.Cache.Helper, as: CacheHelper
  alias Helix.Cache.Internal.Builder, as: BuilderInternal

  setup do
    CacheHelper.cache_context()
  end

  describe "build by_server" do
    test "default case", context do
      server_id = context.server.server_id

      assert {:ok, build} = BuilderInternal.by_server(server_id)

      assert_id build.server_id, server_id
      assert build.storages
      assert build.networks
    end

    test "server without mobo", context do
      server_id = context.server.server_id

      server_id
      |> ServerInternal.fetch()
      |> ServerInternal.detach()

      assert {:ok, build} = BuilderInternal.by_server(server_id)

      assert_id build.server_id, server_id
      assert Enum.empty?(build.storages)
      assert Enum.empty?(build.networks)

      CacheHelper.sync_test()
    end
  end

  describe "build by_storage" do
    test "default case", context do
      server_id = context.server.server_id

      {:ok, server} = BuilderInternal.by_server(server_id)
      storage_id = Enum.random(server.storages)

      assert {:ok, storage} = BuilderInternal.by_storage(storage_id)

      assert_id storage.storage_id, storage_id
      assert_id storage.server_id, server_id
    end

    test "invalid storage" do
      id = Storage.ID.generate()
      assert {:error, reason} = BuilderInternal.by_storage(id)
      assert reason == {:storage, :notfound}
    end

    test "storage without drive", context do
      server_id = context.server.server_id
      motherboard_id = context.server.motherboard_id

      motherboard = MotherboardInternal.fetch(motherboard_id)

      {:ok, server} = BuilderInternal.by_server(server_id)
      storage_id = Enum.random(server.storages)

      hdd = Enum.random(MotherboardInternal.get_hdds(motherboard))

      StorageDriveInternal.unlink_drive(hdd.component_id)

      assert {:error, reason} = BuilderInternal.by_storage(storage_id)
      assert reason == {:drive, :notfound}

      CacheHelper.sync_test()
    end

    test "storage with hdd unlinked", context do
      server_id = context.server.server_id
      motherboard_id = context.server.motherboard_id

      {:ok, server} = BuilderInternal.by_server(server_id)
      storage_id = Enum.random(server.storages)

      motherboard = MotherboardInternal.fetch(motherboard_id)

      hdd =
        motherboard
        |> MotherboardInternal.get_hdds()
        |> Enum.random()

      MotherboardInternal.unlink(hdd)

      assert {:error, reason} = BuilderInternal.by_storage(storage_id)
      assert reason == {:drive, :unlinked}

      CacheHelper.sync_test()
    end
  end

  describe "build by_nip" do
    test "default case", context do
      server_id = context.server.server_id

      {:ok, server} = BuilderInternal.by_server(server_id)
      nip = Enum.random(server.networks)

      assert {:ok, network} = BuilderInternal.by_nip(nip.network_id, nip.ip)

      assert network.network_id == nip.network_id
      assert network.ip == nip.ip
      assert_id network.server_id, server_id
    end

    test "non-existing nip" do
      assert {:error, reason} = BuilderInternal.by_nip("::", Random.ipv4())
      assert reason == {:nip, :notfound}
    end
  end

  describe "build web_by_nip" do
    test "it works with valid npc" do
      dc = Seed.search_by_type(:download_center)
      server = List.first(dc.servers)

      assert {:ok, build} = BuilderInternal.web_by_nip("::", server.static_ip)
      assert build.ip == server.static_ip
      assert build.content
    end

    test "it blows with non-existing nip" do
      assert {:error, reason} = BuilderInternal.web_by_nip("::", Random.ipv4())
      assert reason == {:nip, :notfound}
    end

    @tag :pending
    test "it works  with valid account without webserver" do
    end

    @tag :pending
    test "it works with valid account with webserver" do
    end
  end
end
