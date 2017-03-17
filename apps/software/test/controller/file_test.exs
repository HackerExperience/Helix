defmodule Helix.Software.Controller.FileTest do

  use ExUnit.Case, async: true

  # alias HELL.TestHelper.Random
  alias Helix.Software.Controller.File, as: FileController

  alias Helix.Software.Factory

  def generate_params do
    storage = Factory.insert(:storage)

    :file
    |> Factory.params_for()
    |> Map.put(:storage_id, storage.storage_id)
    |> Map.drop([:inserted_at, :updated_at])
  end

  describe "creating" do
    test "succeeds with valid params" do
      params = generate_params()
      {:ok, file} = FileController.create(params)

      got = Map.take(file, Map.keys(params))
      assert params == got
    end

    test "fails on path identity conflict" do
      params = generate_params()
      collision = Map.take(params, [:name, :file_path, :file_type, :storage_id])

      {:ok, _} = FileController.create(params)

      params = Map.merge(generate_params(), collision)
      assert {:error, :file_exists} == FileController.create(params)
    end
  end

  describe "fetching" do
    test "returns a record based on its identification" do
      file = Factory.insert(:file)
      assert FileController.fetch(file.file_id)
    end

    test "returns nil if file with id doesn't exist" do
      bogus = Factory.build(:file)
      refute FileController.fetch(bogus.file_id)
    end
  end

  describe "updating" do
    test "succeeds with valid params" do
      file = Factory.insert(:file)

      # update name
      params = Map.take(Factory.params_for(:file), [:name])
      {:ok, updated} = FileController.update(file, params)

      refute file.name == updated.name
      assert params.name == updated.name

      # update file_path
      params = Map.take(Factory.params_for(:file), [:file_path])
      {:ok, updated} = FileController.update(file, params)

      refute file.file_path == updated.file_path
      assert params.file_path == updated.file_path

      # update storage
      storage = Factory.insert(:storage)
      params = %{storage_id: storage.storage_id}
      {:ok, updated} = FileController.update(file, params)

      refute file.storage_id == updated.storage_id
      assert params.storage_id == updated.storage_id
    end

    test "fails on path identity conflict" do
      file0 = Factory.insert(:file)
      similarities =  Map.take(file0, [:file_type, :storage, :storage_id])
      file1 =
        :file
        |> Factory.build()
        |> Map.merge(similarities)
        |> Factory.insert()

      file1 = FileController.fetch(file1.file_id)

      params = %{file_path: file0.file_path, name: file0.name}
      assert {:error, :file_exists} == FileController.update(file1, params)

      found = FileController.fetch(file1.file_id)

      assert file1 == found
    end
  end

  describe "copying" do
    test "to another path in the same storage" do
      path = Factory.params_for(:file).file_path
      origin = Factory.insert(:file)

      {:ok, copy} = FileController.copy(origin, path, origin.storage_id)

      assert FileController.fetch(origin.file_id)
      assert FileController.fetch(copy.file_id)

      assert path == copy.file_path
    end

    test "to another storage" do
      storage = Factory.insert(:storage)
      origin = Factory.insert(:file)

      {:ok, copy} =
        FileController.copy(origin, origin.file_path, storage.storage_id)

      assert FileController.fetch(origin.file_id)
      assert FileController.fetch(copy.file_id)

      assert storage.storage_id == copy.storage_id
    end

    test "fails on path identity conflict" do
      origin = Factory.insert(:file)
      assert {:error, :file_exists} ==
        FileController.copy(origin, origin.file_path, origin.storage_id)
    end
  end

  describe "moving" do
    test "to another path" do
      file = Factory.insert(:file)
      path = Factory.params_for(:file).file_path

      {:ok, file} = FileController.move(file, path, file.storage_id)

      assert path == file.file_path
    end

    @tag :pending
    test "to another storage" do
      # REVIEW: I think this should not be allowed. You don't move a file to
      #   another storage, you copy it and delete the original
    end

    test "fails on path identity conflict" do
      file0 = Factory.insert(:file)
      similarities = Map.take(file0, [:name, :storage, :storage_id, :file_type])
      file1 =
        :file
        |> Factory.build()
        |> Map.merge(similarities)
        |> Factory.insert()

      assert {:error, :file_exists} ==
        FileController.move(file1, file0.file_path, file0.storage_id)
    end
  end

  describe "renaming" do
    test "succeeds with a valid non-conflicting name" do
      file = Factory.insert(:file)
      name = Factory.params_for(:file).name

      {:ok, file} = FileController.rename(file, name)

      assert name == file.name
    end

    test "fails on path identity conflict" do
      file0 = Factory.insert(:file)
      similarities =
        Map.take(file0, [:file_path, :file_type, :storage, :storage_id])
      file1 =
        :file
        |> Factory.build()
        |> Map.merge(similarities)
        |> Factory.insert()

      assert {:error, :file_exists} == FileController.rename(file1, file0.name)
    end
  end

  describe "deleting" do
    test "is idempotent" do
      file = Factory.insert(:file)

      assert FileController.fetch(file.file_id)

      FileController.delete(file.file_id)
      FileController.delete(file.file_id)

      refute FileController.fetch(file.file_id)
    end

    test "can be done by its id or its struct" do
      file = Factory.insert(:file)
      assert FileController.fetch(file.file_id)
      FileController.delete(file.file_id)
      refute FileController.fetch(file.file_id)

      file = Factory.insert(:file)
      assert FileController.fetch(file.file_id)
      FileController.delete(file.file_id)
      refute FileController.fetch(file.file_id)
    end
  end
end