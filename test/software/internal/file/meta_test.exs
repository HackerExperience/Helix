defmodule Helix.Software.Internal.File.MetaTest do

  use Helix.Test.Case.Integration

  alias Helix.Software.Internal.File, as: FileInternal
  alias Helix.Software.Internal.Virus, as: VirusInternal

  alias Helix.Test.Entity.Helper, as: EntityHelper
  alias Helix.Test.Software.Setup, as: SoftwareSetup

  describe "gather_metadata/1" do
    test "when file is virus" do
      file = SoftwareSetup.file!(type: :virus_spyware)

      assert %{meta: meta} = FileInternal.Meta.gather_metadata(file)
      refute meta.installed?

      VirusInternal.install(file, EntityHelper.id())

      assert %{meta: meta} = FileInternal.Meta.gather_metadata(file)
      assert meta.installed?
    end
  end
end
