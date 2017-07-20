defmodule Helix.Software.Internal.TextFileTest do

  use Helix.Test.IntegrationCase

  alias HELL.TestHelper.Random
  alias Helix.Software.Internal.File, as: FileInternal
  alias Helix.Software.Internal.TextFile, as: TextFileInternal
  alias Helix.Software.Model.TextFile

  alias Helix.Software.Factory

  def generate_path do
    1..5
    |> Random.repeat(&Random.username/0)
    |> Enum.join("/")
    |> String.replace_prefix("", "/")
  end

  describe "create/3" do
    test "will create a file for the text on storage" do
      storage = Factory.insert(:storage)
      name = Random.username()
      path = generate_path()
      contents = Random.string(max: 100)

      result = TextFileInternal.create(storage, name, path, contents)

      assert {:ok, text_file} = result
      assert FileInternal.fetch(text_file.file_id)
    end
  end

  describe "fetch!/1" do
    test "succeeds by id" do
      text_file = Factory.insert(:text_file)
      assert %TextFile{} = TextFileInternal.fetch!(text_file.file_id)
    end

    test "succeeds by file struct" do
      text_file = Factory.insert(:text_file)
      assert %TextFile{} = TextFileInternal.fetch!(text_file.file)
    end

    test "raises Ecto.NoResultsError when file doesn't exists" do
      assert_raise Ecto.NoResultsError, fn ->
        refute TextFileInternal.fetch!(Random.pk())
      end
    end
  end

  describe "update_contents/2" do
    test "succeeds with valid input" do
      text_file = Factory.insert(:text_file)
      result =  TextFileInternal.update_contents(text_file, "example text")

      assert {:ok, %TextFile{}} = result
    end
  end
end
