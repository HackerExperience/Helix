defmodule Helix.Software.Model.TextFileTest do

  use ExUnit.Case, async: true

  alias HELL.TestHelper.Random
  alias Helix.Software.Model.TextFile
  alias Helix.Software.Model.Storage

  @moduletag :unit

  def generate_path do
    1..5
    |> Random.repeat(&Random.username/0)
    |> Enum.join("/")
    |> String.replace_prefix("", "/")
  end

  describe "create/2" do
    test "when provided with a storage, file path and file name, succeeds" do
      storage = %Storage{}
      name = Random.username()
      path = generate_path()

      changeset = TextFile.create(storage, name, path, "content")

      assert changeset.valid?
    end
  end

  describe "update_contents/2" do
    test "when provided with a text_file and contents, succeeds" do
      text_file = %TextFile{}
      contents = Random.string(max: 100)

      changeset = TextFile.update_contents(text_file, contents)

      assert changeset.valid?
    end
  end
end
