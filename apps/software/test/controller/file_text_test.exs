defmodule Helix.Software.Controller.FileTextTest do

  use ExUnit.Case, async: true

  alias HELL.TestHelper.Random
  alias Helix.Software.Controller.FileText, as: FileTextController

  alias Helix.Software.Factory

  defp generate_params do
    file = Factory.insert(:file)

    :file_text
    |> Factory.params_for()
    |> Map.put(:file_id, file.file_id)
    |> Map.drop([:inserted_at, :updated_at])
  end

  test "file text creation uses input as expected" do
    params = generate_params()

    {:ok, file_text} = FileTextController.create(params)

    got = Map.take(file_text, Map.keys(params))

    assert params == got
  end

  describe "file text fetching" do
    test "succeeds when file text exists" do
      params = generate_params()

      {:ok, file_text} = FileTextController.create(params)
      {:ok, got} = FileTextController.find(file_text.file_id)

      assert file_text == got
    end

    test "fails when file text doesn't exists" do
      assert {:error, :notfound} = FileTextController.find(Random.pk())
    end
  end

  test "file text modify content" do
    params = generate_params()
    %{contents: contents} = generate_params()

    {:ok, file_text1} = FileTextController.create(params)
    {:ok, file_text2} = FileTextController.update_contents(file_text1, contents)

    assert params.contents == file_text1.contents
    assert contents == file_text2.contents
  end
end