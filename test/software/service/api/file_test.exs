defmodule Helix.Software.Service.API.FileTest do

  use ExUnit.Case, async: true

  alias HELL.TestHelper.Random
  alias Helix.Software.Service.API.File, as: API
  alias Helix.Software.Model.File

  alias Helix.Software.Factory

  @moduletag :integration

  def generate_path do
    1..5
    |> Random.repeat(&Random.username/0)
    |> Enum.join("/")
    |> String.replace_prefix("", "/")
  end

  describe "create/1" do
    test "succeeds with valid input" do
      storage = Factory.insert(:storage)

      params = %{
        storage_id: storage.storage_id,
        file_size: Random.number(1024..1_048_576),
        name: Random.username(),
        path: generate_path(),
        software_type: :cracker
      }

      assert {:ok, file} = API.create(params)
      assert params == Map.take(file, Map.keys(params))
    end

    test "fails when input is invalid" do
      params = %{}
      assert {:error, %Ecto.Changeset{}} = API.create(params)
    end
  end

  describe "fetch/1" do
    test "succeeds with valid input" do
      file = Factory.insert(:file)
      assert %File{} = API.fetch(file.file_id)
    end

    test "fails when file doesn't exist" do
      refute API.fetch(Random.pk())
    end
  end

  describe "storage_contents/1" do
    test "succeeds with valid input" do
      storage = Factory.insert(:storage)

      contents = API.storage_contents(storage)

      files =
        contents
        |> Map.values()
        |> List.flatten()

      # asserts that it gets the expected number of files and that these
      # files are consistently grouped by their path
      assert Enum.count(storage.files) == Enum.count(files)
      assert Enum.all?(storage.files, &(&1 in contents[&1.path]))
    end
  end

  describe "files_on_storage/1" do
    test "succeeds with valid input" do
      storage = Factory.insert(:storage)
      refute Enum.empty?(API.files_on_storage(storage))
    end
  end

  describe "copy/3" do
    test "succeeds with valid input" do
      origin = Factory.insert(:file)
      new_path = generate_path()
      new_storage = Factory.insert(:storage)

      assert {:ok, %File{}} = API.copy(origin, origin.storage, new_path)
      assert {:ok, %File{}} = API.copy(origin, new_storage, origin.path)
    end
  end

  describe "move/2" do
    test "succeeds with valid input" do
      origin = Factory.insert(:file)
      new_path = generate_path()

      assert {:ok, %File{}} = API.move(origin, new_path)
      assert {:ok, %File{}} = API.move(origin, origin.path)
    end
  end

  describe "rename/2" do
    test "succeeds with valid input" do
      file = Factory.insert(:file)
      new_name = Random.username()

      assert {:ok, %File{}} = API.rename(file, new_name)
    end
  end

  describe "encrypt/2" do
    test " succeeds with valid input" do
      file = Factory.insert(:file)
      assert {:ok, %File{}} = API.encrypt(file, 1)
    end
  end

  describe "decrypt/1" do
    test "succeeds with valid input" do
      file = Factory.insert(:file)
      assert {:ok, %File{}} = API.decrypt(file)
    end
  end

  describe "delete/1" do
    test "is idempotent" do
      file = Factory.insert(:file)

      API.delete(file)
      API.delete(file)

      refute API.fetch(file.file_id)
    end
  end
end
