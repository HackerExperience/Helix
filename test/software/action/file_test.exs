defmodule Helix.Software.Action.FileTest do

  use Helix.Test.Case.Integration

  alias HELL.TestHelper.Random
  alias Helix.Software.Action.File, as: FileAction
  alias Helix.Software.Model.File
  alias Helix.Software.Query.File, as: FileQuery

  alias Helix.Test.Software.Factory

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

      assert {:ok, file} = FileAction.create(params)
      assert params == Map.take(file, Map.keys(params))
    end

    test "fails when input is invalid" do
      params = %{}
      assert {:error, %Ecto.Changeset{}} = FileAction.create(params)
    end
  end

  describe "copy/3" do
    test "succeeds with valid input" do
      origin = Factory.insert(:file)
      new_path = generate_path()
      new_storage = Factory.insert(:storage)

      assert {:ok, %File{}} = FileAction.copy(origin, origin.storage, new_path)
      assert {:ok, %File{}} = FileAction.copy(origin, new_storage, origin.path)
    end
  end

  describe "move/2" do
    test "succeeds with valid input" do
      origin = Factory.insert(:file)
      new_path = generate_path()

      assert {:ok, %File{}} = FileAction.move(origin, new_path)
      assert {:ok, %File{}} = FileAction.move(origin, origin.path)
    end
  end

  describe "rename/2" do
    test "succeeds with valid input" do
      file = Factory.insert(:file)
      new_name = Random.username()

      assert {:ok, %File{}} = FileAction.rename(file, new_name)
    end
  end

  describe "encrypt/2" do
    test " succeeds with valid input" do
      file = Factory.insert(:file)
      assert {:ok, %File{}} = FileAction.encrypt(file, 1)
    end
  end

  describe "decrypt/1" do
    test "succeeds with valid input" do
      file = Factory.insert(:file)
      assert {:ok, %File{}} = FileAction.decrypt(file)
    end
  end

  describe "delete/1" do
    test "removes entry" do
      file = Factory.insert(:file)

      FileAction.delete(file)

      refute FileQuery.fetch(file.file_id)
    end
  end
end
