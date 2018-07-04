defmodule Helix.Software.Internal.VirusTest do

  use Helix.Test.Case.Integration

  alias Helix.Software.Internal.Virus, as: VirusInternal

  alias Helix.Test.Entity.Helper, as: EntityHelper
  alias Helix.Test.Software.Setup, as: SoftwareSetup

  describe "list_by_storage/1" do
    test "returns all viruses on the given storage" do
      file1 = SoftwareSetup.virus!()
      # `file2` exists on the same storage as `file1`
      file2 = SoftwareSetup.virus!(storage_id: file1.storage_id)

      # `file3` exists on a different storage
      file3 = SoftwareSetup.virus!()

      entity_id = EntityHelper.id()

      # Install all viruses
      {:ok, _} = VirusInternal.install(file1, entity_id)
      {:ok, _} = VirusInternal.install(file2, entity_id)
      {:ok, _} = VirusInternal.install(file3, entity_id)

      # Storage of `file1` has two viruses
      assert viruses = VirusInternal.list_by_storage(file1.storage_id)

      # `file1` and `file2` are installed viruses on the given storage
      assert v1 = Enum.find(viruses, &(&1.file_id == file1.file_id))
      assert v2 = Enum.find(viruses, &(&1.file_id == file2.file_id))

      # v1 was installed; v2 wasn't (2nd virus by same entity on same storage)
      assert v1.is_active?
      assert v1.running_time

      refute v2.is_active?
      refute v2.running_time

      # Storage of `file3` has one virus
      assert [v3] = VirusInternal.list_by_storage(file3.storage_id)
      assert v3.file_id == file3.file_id
      assert v3.is_active?
      assert v3.running_time
    end
  end

  describe "list_by_entity/1" do
    test "returns all viruses installed by the given entity" do
      file1 = SoftwareSetup.virus!()
      file2 = SoftwareSetup.virus!()
      file3 = SoftwareSetup.virus!()

      entity_id1 = EntityHelper.id()
      entity_id2 = EntityHelper.id()

      # `file1` and `file2` were installed by `entity_id1`
      {:ok, _} = VirusInternal.install(file1, entity_id1)
      {:ok, _} = VirusInternal.install(file2, entity_id1)
      {:ok, _} = VirusInternal.install(file3, entity_id2)

      assert viruses = VirusInternal.list_by_entity(entity_id1)

      # `file1` and `file2` were installed by the given entity
      assert Enum.find(viruses, &(&1.file_id == file1.file_id))
      assert Enum.find(viruses, &(&1.file_id == file2.file_id))
      assert Enum.all?(viruses, &(&1.is_active?))
      assert Enum.all?(viruses, &(&1.running_time))
    end
  end

  describe "list_by_storage_and_entity/1" do
    test "returns all viruses installed by the given entity" do
      # Files 1, 2 and 3 are on the same storage
      file1 = SoftwareSetup.virus!()
      file2 = SoftwareSetup.virus!(storage_id: file1.storage_id)
      file3 = SoftwareSetup.virus!(storage_id: file1.storage_id)
      file4 = SoftwareSetup.virus!()

      entity_id1 = EntityHelper.id()
      entity_id2 = EntityHelper.id()

      # Files 1, 2 and 4 were installed by the same entity.
      # File 3 is on the same storage of 1 and 2 but installed by other entity
      {:ok, _} = VirusInternal.install(file1, entity_id1)
      {:ok, _} = VirusInternal.install(file2, entity_id1)
      {:ok, _} = VirusInternal.install(file3, entity_id2)
      {:ok, _} = VirusInternal.install(file4, entity_id1)

      viruses =
        VirusInternal.list_by_storage_and_entity(file1.storage_id, entity_id1)

      # `file1` and `file2` were installed by the given entity on that storage
      assert v1 = Enum.find(viruses, &(&1.file_id == file1.file_id))
      assert v2 = Enum.find(viruses, &(&1.file_id == file2.file_id))

      # v1 is active; v2 isn't (same storage, same entity)
      assert v1.is_active?
      assert v1.running_time

      refute v2.is_active?
      refute v2.running_time

      # On the same storage but by entity2, only one virus was found
      assert [v3] =
        VirusInternal.list_by_storage_and_entity(file3.storage_id, entity_id2)
      assert v3.file_id == file3.file_id
      assert v3.is_active?
      assert v3.running_time
    end
  end

  describe "install/2" do
    test "installs virus and automatically activates it" do
      file = SoftwareSetup.virus!()
      entity_id = EntityHelper.id()

      assert {:ok, virus} = VirusInternal.install(file, entity_id)

      assert virus.entity_id == entity_id
      assert virus.file_id == file.file_id
      assert virus.is_active?
      assert is_integer(virus.running_time)

      db_entry = VirusInternal.fetch(file.file_id)
      assert db_entry == virus
    end

    test "second virus install (same entity, storage) won't auto activate it" do
      entity_id = EntityHelper.id()
      file1 = SoftwareSetup.virus!()

      assert {:ok, virus1} = VirusInternal.install(file1, entity_id)

      # virus1 returned from `install/2` has been formatted and marks as active
      assert virus1.is_active?
      assert is_integer(virus1.running_time)

      # We have a Virus which is active
      virus1 = VirusInternal.fetch(file1.file_id)
      assert virus1.is_active?

      # Now the same entity will install another virus on the same storage
      file2 = SoftwareSetup.virus!(storage_id: file1.storage_id)

      assert {:ok, virus2} = VirusInternal.install(file2, entity_id)

      # virus2 is inactive
      refute virus2.is_active?
      refute virus2.running_time

      virus2 = VirusInternal.fetch(file2.file_id)

      # `virus2` returned by `fetch` marks it as being inactive
      assert virus1.is_active?
      refute virus2.is_active?
    end
  end

  describe "activate_virus/2" do
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
      assert virus1.running_time

      # But subsequent `virus2` wasn't activated
      refute virus2.is_active?
      refute virus2.running_time

      # Let's activate `virus2`
      assert {:ok, new_virus2} =
        VirusInternal.activate_virus(virus2, file2.storage_id)

      # Now it's running!
      assert new_virus2.is_active?
      assert new_virus2.running_time

      # `virus2` is now active and `virus1` isn't
      refute VirusInternal.is_active?(virus1.file_id)
      assert VirusInternal.is_active?(virus2.file_id)
    end
  end

  describe "set_running_time/2" do
    test "modifies the running time of a virus" do
      {virus, %{file: _}} = SoftwareSetup.Virus.virus()

      assert {:ok, virus2} = VirusInternal.set_running_time(virus, 60)
      assert virus2.running_time == 60

      assert {:ok, virus3} = VirusInternal.set_running_time(virus, -100)
      assert virus3.running_time == -100

      assert {:ok, virus4} = VirusInternal.set_running_time(virus, 0)
      assert virus4.running_time == 0
    end
  end
end
