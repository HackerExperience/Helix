defmodule Helix.Software.Internal.StorageTest do

  use Helix.Test.Case.Integration

  alias Helix.Software.Internal.Storage, as: StorageInternal
  alias Helix.Software.Model.Storage

  alias Helix.Test.Cache.Helper, as: CacheHelper
  alias Helix.Test.Software.Setup, as: SoftwareSetup

  describe "create/1" do
    test "it works" do
      assert {:ok, _} = StorageInternal.create()
    end
  end

  describe "fetching" do
    test "returns a record based on its identification" do
      {storage, _} = SoftwareSetup.storage()
      assert %Storage{} = StorageInternal.fetch(storage.storage_id)
    end

    test "returns nil if storage doesn't exists" do
      refute StorageInternal.fetch(Storage.ID.generate())
    end
  end

  test "delete/1 removes entry" do
    {storage, _} = SoftwareSetup.storage()

    assert StorageInternal.fetch(storage.storage_id)

    StorageInternal.delete(storage)

    refute StorageInternal.fetch(storage.storage_id)

    CacheHelper.sync_test()
  end
end
