defmodule Helix.Software.Henforcer.VirusTest do

  use Helix.Test.Case.Integration

  import Helix.Test.Henforcer.Macros

  alias Helix.Software.Action.Virus, as: VirusAction
  alias Helix.Software.Henforcer.Virus, as: VirusHenforcer

  alias Helix.Test.Entity.Setup, as: EntitySetup
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Universe.Bank.Setup, as: BankSetup
  alias Helix.Test.Software.Helper, as: SoftwareHelper
  alias Helix.Test.Software.Setup, as: SoftwareSetup

  describe "can_install?/2" do
    test "accepts when everything is OK" do
      # We have an entity installing the virus on a remote server. All OK
      {entity, _} = EntitySetup.entity()
      {target, _} = ServerSetup.server()

      storage = SoftwareHelper.get_storage(target)
      virus = SoftwareSetup.virus!(storage_id: storage.storage_id)

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
      file = SoftwareSetup.virus!(storage_id: storage.storage_id)

      assert {false, reason, _} = VirusHenforcer.can_install?(file, entity)

      assert reason == {:virus, :self_install}
    end

    test "refuses when file is not a virus" do
      {entity, _} = EntitySetup.entity()
      {target, _} = ServerSetup.server()

      storage = SoftwareHelper.get_storage(target)
      not_virus =
        SoftwareSetup.file!(type: :cracker, storage_id: storage.storage_id)

      assert {false, reason, _} = VirusHenforcer.can_install?(not_virus, entity)
      assert reason == {:file, :not_virus}
    end

    test "refuses when virus is already active (installed)" do
      {entity, _} = EntitySetup.entity()
      {target, _} = ServerSetup.server()

      storage = SoftwareHelper.get_storage(target)
      virus = SoftwareSetup.virus!(storage_id: storage.storage_id)

      # Virus has already been installed by someone else
      assert {:ok, _, _} = VirusAction.install(virus, EntitySetup.id())

      assert {false, reason, _} = VirusHenforcer.can_install?(virus, entity)
      assert reason == {:virus, :active}
    end

    test "refuses when entity already has one virus installed on target" do
      {entity, _} = EntitySetup.entity()
      {target, _} = ServerSetup.server()

      storage = SoftwareHelper.get_storage(target)
      virus1 = SoftwareSetup.virus!(storage_id: storage.storage_id)
      virus2 = SoftwareSetup.virus!(storage_id: storage.storage_id)

      # Virus1 has been installed
      assert {:ok, _, _} = VirusAction.install(virus1, entity.entity_id)

      assert {false, reason, _} = VirusHenforcer.can_install?(virus2, entity)
      assert reason == {:entity, :has_virus_on_storage}
    end
  end

  describe "can_collect_all?/3" do
    test "handles multiple viruses and accepts when everything is OK" do
      {entity, _} = EntitySetup.entity()

      {virus1, %{file: file1}} =
        SoftwareSetup.Virus.virus(
          entity_id: entity.entity_id,
          is_active?: true,
          real_file?: true
        )

      {virus2, %{file: file2}} =
        SoftwareSetup.Virus.virus(
          entity_id: entity.entity_id,
          is_active?: true,
          real_file?: true
        )

      {virus3, %{file: file3}} =
        SoftwareSetup.Virus.virus(
          entity_id: entity.entity_id,
          is_active?: true,
          real_file?: true
        )

      viruses = [file1.file_id, file2.file_id, file3.file_id]

      bank_account = BankSetup.fake_account()

      assert {true, relay} =
        VirusHenforcer.can_collect_all?(entity, viruses, {bank_account, nil})

      Enum.each(relay.viruses, fn %{file: file, virus: v} ->
        assert Enum.find([file1, file2, file3], &(&1.file_id == file.file_id))
        assert Enum.find([virus1, virus2, virus3], &(&1.file_id == v.file_id))
      end)

      assert_relay relay, [:viruses]
    end

    test "rejects when something is wrong" do
      {entity, _} = EntitySetup.entity()

      {virus1, %{file: file1}} =
        SoftwareSetup.Virus.virus(
          entity_id: EntitySetup.id(),
          is_active?: true,
          real_file?: true
        )

      {_virus2, %{file: file2}} =
        SoftwareSetup.Virus.virus(
          entity_id: entity.entity_id,
          is_active?: true,
          real_file?: true
        )

      # `virus1` was installed by someone else
      refute virus1.entity_id == entity.entity_id

      viruses = [file1.file_id, file2.file_id]

      assert {false, reason, _} =
        VirusHenforcer.can_collect_all?(entity, viruses, {nil, nil})

      assert reason == {:virus, :not_belongs}
    end
  end

  describe "can_collect?/3" do
    test "accepts when everything is OK" do
      {entity, _} = EntitySetup.entity()

      {virus, %{file: file}} =
        SoftwareSetup.Virus.virus(
          entity_id: entity.entity_id,
          is_active?: true,
          real_file?: true
        )

      bank_account = BankSetup.fake_account()

      assert {true, relay} =
        VirusHenforcer.can_collect?(entity, file.file_id, {bank_account, nil})

      assert relay.virus == virus
      assert relay.entity == entity
      assert relay.file == file

      assert_relay relay, [:virus, :file, :entity]
    end

    test "rejects when entity did not install the virus" do
      {entity, _} = EntitySetup.entity()

      {virus, %{file: file}} =
        SoftwareSetup.Virus.virus(
          entity_id: EntitySetup.id(),  # Random entity
          is_active?: true,
          real_file?: true
        )

      # See? Someone else installed that virus
      refute virus.entity_id == entity.entity_id

      bank_account = BankSetup.fake_account()

      assert {false, reason, _} =
        VirusHenforcer.can_collect?(entity, file.file_id, {bank_account, nil})
      assert reason == {:virus, :not_belongs}
    end

    test "rejects when virus is not active" do
      {entity, _} = EntitySetup.entity()

      {virus, %{file: file}} =
        SoftwareSetup.Virus.virus(
          entity_id: entity.entity_id,
          is_active?: false,
          real_file?: true
        )

      # Not active
      refute virus.is_active?

      bank_account = BankSetup.fake_account()

      assert {false, reason, _} =
        VirusHenforcer.can_collect?(entity, file.file_id, {bank_account, nil})
      assert reason == {:virus, :not_active}
    end

    test "rejects when virus does not exist" do
      {entity, _} = EntitySetup.entity()

      assert {false, reason, _} =
        VirusHenforcer.can_collect?(entity, SoftwareSetup.id(), {nil, nil})
      assert reason == {:virus, :not_found}
    end

    test "rejects when payment is invalid (for bank-based viruses)" do
      {entity, _} = EntitySetup.entity()

      {_, %{file: spyware}} =
        SoftwareSetup.Virus.virus(
          entity_id: entity.entity_id,
          is_active?: true,
          real_file?: true,
          type: :virus_spyware
        )

      assert {false, reason, _} =
        VirusHenforcer.can_collect?(entity, spyware.file_id, {nil, %{}})

      assert reason == {:payment, :invalid}

      # TODO: Waiting Bitcoin implementation for full test (#244)
      # Also add an extra test on `can_collect_all?/3`
    end
  end
end
