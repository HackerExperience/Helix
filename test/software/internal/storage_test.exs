defmodule Helix.Software.Internal.StorageTest do

  use Helix.Test.IntegrationCase

  alias Helix.Software.Internal.Storage, as: StorageInternal
  alias Helix.Software.Model.Storage

  alias Helix.Cache.Helper, as: CacheHelper
  alias Helix.Software.Factory

  describe "create/1" do
    test "it works" do
      assert {:ok, _} = StorageInternal.create()
    end
  end

  describe "fetching" do
    test "returns a record based on its identification" do
      storage = Factory.insert(:storage)
      assert %Storage{} = StorageInternal.fetch(storage.storage_id)
    end

    test "returns nil if storage with id doesn't exists" do
      storage_id = Storage.ID.generate()
      refute StorageInternal.fetch(storage_id)
    end
  end

  test "delete/1 removes entry" do
    storage = Factory.insert(:storage)

    assert StorageInternal.fetch(storage.storage_id)
    StorageInternal.delete(storage)
    refute StorageInternal.fetch(storage.storage_id)

    CacheHelper.sync_test()
  end
end
