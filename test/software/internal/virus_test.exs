defmodule Helix.Software.Internal.VirusTest do

  use Helix.Test.Case.Integration

  alias Helix.Software.Internal.Virus, as: VirusInternal

  alias Helix.Test.Entity.Setup, as: EntitySetup
  alias Helix.Test.Software.Setup, as: SoftwareSetup

  describe "install/2" do
    test "installs virus and automatically activates it" do
      {file, _} = SoftwareSetup.file(type: :virus_spyware)
      entity_id = EntitySetup.id()

      assert {:ok, virus} = VirusInternal.install(file, entity_id)

      assert virus.entity_id == entity_id
      assert virus.file_id == file.file_id
      assert virus.storage_id == file.storage_id
      assert virus.is_active?

      db_entry = VirusInternal.fetch(file.file_id)
      assert db_entry == virus
    end

    test "second virus install (same entity, storage) won't auto activate it" do
      entity_id = EntitySetup.id()
      file1 = SoftwareSetup.file!(type: :virus_spyware)

      assert {:ok, virus1} = VirusInternal.install(file1, entity_id)

      # virus1 returned from `install/2` has been formatted and marks as active
      assert virus1.is_active?

      # We have a Virus which is active
      virus1 = VirusInternal.fetch(file1.file_id)
      assert virus1.is_active?

      # Now the same entity will install another virus on the same storage
      file2 =
        SoftwareSetup.file!(type: :virus_spyware, storage_id: file1.storage_id)

      assert {:ok, virus2} = VirusInternal.install(file2, entity_id)

      # virus2 is inactive
      assert virus1.is_active?
      refute virus2.is_active?

      virus2 = VirusInternal.fetch(file2.file_id)

      # `virus2` returned by `fetch` marks it as being inactive
      assert virus1.is_active?
      refute virus2.is_active?
    end
  end

  describe "activate_virus/1" do
    test "overwrites current active virus" do
      {%{entity_id: entity_id}, %{file: file1}} = SoftwareSetup.Virus.virus()
      {_, %{file: file2}} =
        SoftwareSetup.Virus.virus(
          storage_id: file1.storage_id, entity_id: entity_id, is_active?: false
        )

      virus1 = VirusInternal.fetch(file1.file_id)
      virus2 = VirusInternal.fetch(file2.file_id)

      # `virus1` is active, as it was the first to be added
      assert virus1.is_active?

      # But subsequent `virus2` wasn't activated
      refute virus2.is_active?

      # Let's activate `virus2`
      assert {:ok, new_virus2} = VirusInternal.activate_virus(virus2)
      assert new_virus2.is_active?

      # `virus2` is now active and `virus1` isn't
      refute VirusInternal.is_active?(virus1.file_id)
      assert VirusInternal.is_active?(virus2.file_id)
    end
  end
end
