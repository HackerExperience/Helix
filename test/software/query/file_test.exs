defmodule Helix.Software.Query.FileTest do

  use Helix.Test.Case.Integration

  alias Helix.Software.Model.File
  alias Helix.Software.Query.File, as: FileQuery

  alias Helix.Test.Software.Setup, as: SoftwareSetup

  @moduletag :integration

  describe "fetch/1" do
    test "succeeds with valid input" do
      {file, _} = SoftwareSetup.file()

      entry = FileQuery.fetch(file.file_id)
      assert entry == file
    end

    test "fails when file doesn't exist" do
      refute FileQuery.fetch(File.ID.generate())
    end
  end
end
