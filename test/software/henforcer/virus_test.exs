defmodule Helix.Software.Henforcer.VirusTest do

  use Helix.Test.Case.Integration

  import Helix.Test.Henforcer.Macros

  alias Helix.Software.Action.Virus, as: VirusAction
  alias Helix.Software.Henforcer.Virus, as: VirusHenforcer

  alias Helix.Test.Entity.Setup, as: EntitySetup
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Software.Helper, as: SoftwareHelper
  alias Helix.Test.Software.Setup, as: SoftwareSetup

  describe "can_install?/2" do
    test "accepts when everything is OK" do
      # We have an entity installing the virus on a remote server. All OK
      {entity, _} = EntitySetup.entity()
      {target, _} = ServerSetup.server()

      storage = SoftwareHelper.get_storage(target)
      virus = SoftwareSetup.virus!(storage_id: storage)

      assert {true, relay} = VirusHenforcer.can_install?(virus, entity)

      assert relay.entity == entity
      assert relay.file == virus
      assert relay.storage == storage

      assert_relay relay, [:entity, :file, :storage]
    end

    test "refuses when installing virus on player's own storage (server)" do
      # Entity who owns `server` is install virus on `server`
      {server, %{entity: entity}} = ServerSetup.server()

      storage = SoftwareHelper.get_storage(server)
      file = SoftwareSetup.virus!(storage_id: storage)

      assert {false, reason, _} = VirusHenforcer.can_install?(file, entity)

      assert reason == {:virus, :self_install}
    end

    test "refuses when file is not a virus" do
      {entity, _} = EntitySetup.entity()
      {target, _} = ServerSetup.server()

      storage = SoftwareHelper.get_storage(target)
      not_virus = SoftwareSetup.file!(type: :cracker, storage_id: storage)

      assert {false, reason, _} = VirusHenforcer.can_install?(not_virus, entity)
      assert reason == {:file, :not_virus}
    end

    test "refuses when virus is already active (installed)" do
      {entity, _} = EntitySetup.entity()
      {target, _} = ServerSetup.server()

      storage = SoftwareHelper.get_storage(target)
      virus = SoftwareSetup.virus!(storage_id: storage)

      # Virus has already been installed by someone else
      assert {:ok, _, _} = VirusAction.install(virus, EntitySetup.id())

      assert {false, reason, _} = VirusHenforcer.can_install?(virus, entity)
      assert reason == {:virus, :active}
    end

    test "refuses when entity already has one virus installed on target" do
      {entity, _} = EntitySetup.entity()
      {target, _} = ServerSetup.server()

      storage = SoftwareHelper.get_storage(target)
      virus1 = SoftwareSetup.virus!(storage_id: storage)
      virus2 = SoftwareSetup.virus!(storage_id: storage)

      # Virus1 has been installed
      assert {:ok, _, _} = VirusAction.install(virus1, entity.entity_id)

      assert {false, reason, _} = VirusHenforcer.can_install?(virus2, entity)
      assert reason == {:entity, :has_virus_on_storage}
    end
  end
end
