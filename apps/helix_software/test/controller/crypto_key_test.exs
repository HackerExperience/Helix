defmodule Helix.Software.Controller.CryptoKeyTest do

  use ExUnit.Case, async: true

  alias HELL.TestHelper.Random
  alias Helix.Software.Controller.CryptoKey, as: CryptoKeyController
  alias Helix.Software.Controller.File, as: FileController

  alias Helix.Software.Factory

  describe "create/3" do
    test "will create a file for the key on storage" do
      storage = Factory.insert(:storage, %{files: []})
      random_files = Factory.insert_list(5, :file, %{crypto_version: 1})
      server_id = Random.pk()

      create_key = &CryptoKeyController.create(storage, server_id, &1)
      Enum.each(random_files, create_key)

      files = FileController.get_files_on_target_storage(storage, storage)

      assert 5 == Enum.count(files)
      assert Enum.all?(files, &(&1.software_type == "crypto_key"))
    end
  end
end
