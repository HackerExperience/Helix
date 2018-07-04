defmodule Helix.Software.Henforcer.File.InstallTest do

  use Helix.Test.Case.Integration

  import Helix.Test.Henforcer.Macros

  alias Helix.Software.Henforcer.File, as: FileHenforcer

  alias Helix.Test.Entity.Setup, as: EntitySetup
  alias Helix.Test.Software.Helper, as: SoftwareHelper
  alias Helix.Test.Software.Setup, as: SoftwareSetup

  describe "can_install?/2" do
    test "accepts when everything is OK" do
      {entity, _} = EntitySetup.entity()

      # Virus is installable
      virus = SoftwareSetup.virus!()

      assert {true, relay} =
        FileHenforcer.Install.can_install?(virus.file_id, entity.entity_id)

      assert relay.file == virus
      assert relay.entity == entity

      assert_relay relay, [:file, :entity]
    end
  end

  describe "is_installable/1" do
    test "accepts when file is installable" do
      installable = SoftwareSetup.virus!()

      assert {true, relay} =
        FileHenforcer.Install.is_installable?(installable.file_id)

      assert relay.file == installable

      assert_relay relay, [:file]
    end

    test "rejects when file is not installabe" do
      not_installable = SoftwareSetup.cracker!()

      assert {false, reason, _} =
        FileHenforcer.Install.is_installable?(not_installable.file_id)
      assert reason == {:file, :not_installable}
    end

    test "rejects when file does not exist" do
      assert {false, reason, _} =
        FileHenforcer.Install.is_installable?(SoftwareHelper.id())
      assert reason == {:file, :not_found}
    end
  end
end
