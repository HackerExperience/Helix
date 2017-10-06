defmodule Helix.Software.Henforcer.FileTest do

  use Helix.Test.Case.Integration

  alias Helix.Software.Henforcer.File, as: FileHenforcer
  alias Helix.Software.Model.File

  alias Helix.Test.Software.Setup, as: SoftwareSetup

  describe "file_exists?/1" do
    test "returns true when file exists" do
      {file, _} = SoftwareSetup.file()
      assert {true, relay} = FileHenforcer.file_exists?(file.file_id)
      assert relay.file.file_id == file.file_id
    end

    test "non-existing file" do
      assert {false, reason, _} = FileHenforcer.file_exists?(File.ID.generate())
      assert reason == {:file, :not_found}
    end
  end
end
