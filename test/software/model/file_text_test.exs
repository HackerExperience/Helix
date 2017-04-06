defmodule Helix.Software.Model.FileTextTest do

  use ExUnit.Case, async: true

  alias HELL.TestHelper.Random
  alias Helix.Software.Model.FileText
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

      params = %{
        name: Random.username(),
        path: generate_path()
      }

      changeset = FileText.create(storage, params)

      assert changeset.valid?
    end
  end

  describe "update_contents/2" do
    test "when provided with a file_text and contents, succeeds" do
      file_text = %FileText{}
      contents = Random.string(max: 100)

      changeset = FileText.update_contents(file_text, contents)

      assert changeset.valid?
    end
  end
end
