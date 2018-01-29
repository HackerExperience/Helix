defmodule Helix.Software.Henforcer.Virus do

  import Helix.Henforcer

  alias Helix.Entity.Henforcer.Entity, as: EntityHenforcer
  alias Helix.Entity.Model.Entity
  alias Helix.Software.Henforcer.File, as: FileHenforcer
  alias Helix.Software.Henforcer.Storage, as: StorageHenforcer
  alias Helix.Software.Model.File
  alias Helix.Software.Model.Storage
  alias Helix.Software.Query.Virus, as: VirusQuery

  @type can_install_relay ::
    %{file: File.t, entity: Entity.t, storage: Storage.t}
  @type can_install_relay_partial :: map
  @type can_install_error ::
    {false, {:virus, :self_install}, can_install_relay_partial}
    | FileHenforcer.is_virus_error
    | not_is_active_error
    | not_entity_has_virus_on_storage_error

  @spec can_install?(File.t, Entity.t) ::
    {true, can_install_relay}
    | can_install_error
  @doc """
  Verifies whether virus (`file`) may be installed by `entity`.

  Among other things, it makes sure `file` is a virus that hasn't been installed
  yet, and that `entity` isn't installing it on herself (or for the second time
  on the same server).
  """
  def can_install?(file = %File{}, entity = %Entity{}) do
    with \
      {true, r1} <- FileHenforcer.is_virus?(file),
      {true, _} <- not_is_active?(file),
      {true, r2} <- not_entity_has_virus_on_storage?(entity, file.storage_id),
      {true, _} <- henforce_not(
        EntityHenforcer.owns_storage?(entity, r2.storage),
        {:virus, :self_install}
      )
    do
      reply_ok(relay(r1, r2))
    end
  end

  @type is_active_relay :: %{file: File.t}
  @type is_active_relay_partial :: is_active_relay
  @type is_active_error ::
    {false, {:virus, :not_active}, is_active_relay_partial}
    | FileHenforcer.file_exists_error

  @spec is_active?(File.idt) ::
    {true, is_active_relay}
    | is_active_error
  @doc """
  Henforces the given virus is active (installed).
  """
  def is_active?(file_id = %File.ID{}) do
    henforce FileHenforcer.file_exists?(file_id) do
      is_active?(relay.file)
    end
  end

  def is_active?(file = %File{}) do
    if VirusQuery.is_active?(file) do
      reply_ok()
    else
      reply_error({:virus, :not_active})
    end
    |> wrap_relay(%{file: file})
  end

  @type not_is_active_relay :: is_active_relay_partial
  @type not_is_active_relay_partial :: is_active_relay
  @type not_is_active_error ::
    {false, {:virus, :active}, not_is_active_relay_partial}
    | is_active_error

  @spec not_is_active?(File.idt) ::
    {true, not_is_active_relay}
    | not_is_active_error
  @doc """
  Henforces the given virus is NOT active (installed).
  """
  def not_is_active?(file),
    do: henforce_not(is_active?(file), {:virus, :active})

  @type entity_has_virus_on_storage_relay ::
    %{entity: Entity.t, storage: Storage.t}
  @type entity_has_virus_on_storage_relay_partial ::
    entity_has_virus_on_storage_relay
  @type entity_has_virus_on_storage_error ::
    {
      false,
      {:entity, :no_virus_on_storage},
      entity_has_virus_on_storage_relay_partial
    }
    | EntityHenforcer.entity_exists_error
    | StorageHenforcer.storage_exists_error

  @spec entity_has_virus_on_storage?(Entity.idt, Storage.idt) ::
    {true, entity_has_virus_on_storage_relay}
    | entity_has_virus_on_storage_error
  @doc """
  Henforces the entity has at least one virus installed on the given storage.
  """
  def entity_has_virus_on_storage?(entity_id = %Entity.ID{}, storage) do
    henforce EntityHenforcer.entity_exists?(entity_id) do
      entity_has_virus_on_storage?(relay.entity, storage)
    end
  end

  def entity_has_virus_on_storage?(entity, storage_id = %Storage.ID{}) do
    henforce StorageHenforcer.storage_exists?(storage_id) do
      entity_has_virus_on_storage?(entity, relay.storage)
    end
  end

  def entity_has_virus_on_storage?(entity = %Entity{}, storage = %Storage{}) do
    if VirusQuery.entity_has_virus_on_storage?(entity, storage) do
      reply_ok()
    else
      reply_error({:entity, :no_virus_on_storage})
    end
    |> wrap_relay(%{entity: entity, storage: storage})
  end

  @type not_entity_has_virus_on_storage_relay ::
    entity_has_virus_on_storage_relay_partial
  @type not_entity_has_virus_on_storage_relay_partial ::
    entity_has_virus_on_storage_relay
  @type not_entity_has_virus_on_storage_error ::
    {
      false,
      {:entity, :has_virus_on_storage},
      not_entity_has_virus_on_storage_relay_partial
    }
    | entity_has_virus_on_storage_error

  @spec not_entity_has_virus_on_storage?(Entity.idt, Storage.idt) ::
    {true, not_entity_has_virus_on_storage_relay}
    | not_entity_has_virus_on_storage_error
  @doc """
  Henforces the entity does NOT have any virus installed on the given storage.
  """
  def not_entity_has_virus_on_storage?(entity, storage) do
    henforce_not(
      entity_has_virus_on_storage?(entity, storage),
      {:entity, :has_virus_on_storage}
    )
  end
end
