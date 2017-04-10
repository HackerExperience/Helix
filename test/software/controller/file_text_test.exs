defmodule Helix.Software.Controller.FileTextTest do

  use Helix.Test.IntegrationCase

  alias HELL.TestHelper.Random
  alias Helix.Software.Controller.FileText, as: FileTextController
  alias Helix.Software.Model.FileText

  alias Helix.Software.Factory

  defp generate_params do
    %{file_id: file_id} = Factory.insert(:file)
    %{contents: contents} = Factory.build(:file_text)

    %{file_id: file_id, contents: contents}
  end

  describe "creating"do
    test "succeeds with valid params" do
      params = generate_params()
      assert {:ok, _} = FileTextController.create(params)
    end

    test "fails if file with id doesn't exist" do
      file_text = Factory.build(:file_text)
      params = %{file_id: file_text.file_id, contents: file_text.contents}

      assert {:error, cs} = FileTextController.create(params)
      assert :file_id in Keyword.keys(cs.errors)
    end
  end

  describe "fetching" do
    test "returns a record based on its identification" do
      file_text = Factory.insert(:file_text)
      assert %FileText{} = FileTextController.fetch(file_text.file)
    end

    test "returns nil if file_text with id doesn't exists" do
      bogus = Factory.build(:file, %{file_id: Random.pk()})
      refute FileTextController.fetch(bogus)
    end
  end

  test "updating contents" do
    ft = Factory.insert(:file_text)
    %{contents: contents} = Factory.build(:file_text)

    assert {:ok, updated} = FileTextController.update_contents(ft, contents)
    assert contents == updated.contents
  end
end
