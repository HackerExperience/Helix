defmodule Helix.Software.Henforcer.Virus do

  import Helix.Henforcer

  alias Helix.Entity.Henforcer.Entity, as: EntityHenforcer
  alias Helix.Entity.Model.Entity
  alias Helix.Universe.Bank.Model.BankAccount
  alias Helix.Software.Henforcer.File, as: FileHenforcer
  alias Helix.Software.Henforcer.Storage, as: StorageHenforcer
  alias Helix.Software.Model.File
  alias Helix.Software.Model.Storage
  alias Helix.Software.Model.Virus
  alias Helix.Software.Query.Virus, as: VirusQuery

  @type payment_info :: {BankAccount.t | nil, term | nil}

  @type virus_exists_relay :: %{virus: Virus.t}
  @type virus_exists_relay_partial :: %{}
  @type virus_exists_error ::
    {false, {:virus, :not_found}, virus_exists_relay_partial}

  @spec virus_exists?(File.id) ::
    {true, virus_exists_relay}
    | virus_exists_error
  @doc """
  Ensures the given `file_id` represents a valid virus. Note it does not check
  whether the virus is active, use `is_active?` instead!
  """
  def virus_exists?(virus_id = %File.ID{}) do
    with virus = %Virus{} <- VirusQuery.fetch(virus_id) do
      reply_ok(%{virus: virus})
    else
      _ ->
        reply_error({:virus, :not_found})
    end
  end

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

  @type can_collect_all_relay :: %{viruses: [can_collect_relay]}
  @type can_collect_all_relay_partial :: map
  @type can_collect_all_error :: can_collect_error

  @spec can_collect_all?(Entity.t, [File.id], payment_info) ::
    {true, can_collect_all_relay}
    | can_collect_all_error
  @doc """
  Henforces that all given viruses may be collected.

  Under the hood, it simply delegates the verification individually to
  `can_collect/3`, and aggregates the results into the `:viruses` relay.
  """
  def can_collect_all?(entity = %Entity{}, viruses, payment_info) do
    init = {true, %{viruses: []}}

    viruses
    |> Enum.reduce_while(init, fn virus_id, {status, acc} ->
      with {true, relay} <- can_collect?(entity, virus_id, payment_info) do
        relay = drop(relay, :entity)
        new_acc = %{viruses: acc.viruses ++ [relay]}

        {:cont, {status, new_acc}}
      else
        error ->
          {:halt, error}
      end
    end)
  end

  @type can_collect_relay :: %{entity: Entity.t, file: File.t, virus: Virus.t}
  @type can_collect_relay_partial :: map
  @type can_collect_error ::
    EntityHenforcer.owns_virus_error
    | is_active_error
    | valid_payment_error

  @spec can_collect?(Entity.t, File.id, payment_info) ::
    {true, can_collect_relay}
    | can_collect_error
  @doc """
  Verifies whether `entity` may collect money off of `virus_id`. Ensures that:

  - Virus exists & was installed by the entity
  - Virus is currently active
  - The payment information at `payment_info` is valid for that virus
  - Virus may be used to collect money (e.g. DDoS may not)
  """
  def can_collect?(entity = %Entity{}, virus_id = %File.ID{}, payment_info) do
    with \
      {true, r1} <- EntityHenforcer.owns_virus?(entity, virus_id),
      {true, r2} <- is_active?(virus_id),
      file = r2.file,
      {true, _} <- valid_payment?(file, payment_info),
      {true, _} <- is_collectible?(file)
    do
      reply_ok(relay(r1, r2))
    end
  end

  @type valid_payment_relay :: %{}
  @type valid_payment_relay_partial :: %{}
  @type valid_payment_error ::
    {false, {:payment, :invalid}, valid_payment_relay_partial}

  @spec valid_payment?(File.t, payment_info) ::
    {true, valid_payment_relay}
    | valid_payment_error
  @doc """
  Verifies whether the given `payment_info` is valid for that specific virus.

  Viruses of type `miner` requires a bitcoin wallet. Viruses of type `spyware`
  or `spam` require a bank account.
  """
  def valid_payment?(%File{software_type: :virus_miner}, {_, nil}),
    do: reply_error({:payment, :invalid})
  def valid_payment?(%File{software_type: :virus_spyware}, {nil, _}),
    do: reply_error({:payment, :invalid})
  def valid_payment?(_, _),
    do: reply_ok()

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

  @type is_collectible_relay :: %{}
  @type is_collectible_relay_partial :: %{}
  @type is_collectible_error ::
    {false, {:virus, :not_collectible}, is_collectible_relay_partial}

  @spec is_collectible?(File.t) ::
    {true, is_collectible_relay}
    | is_collectible_error
  @doc """
  Henforces that the given File is a virus that can be used to collect money.
  """
  def is_collectible?(%File{software_type: :virus_spyware}),
    do: reply_ok()
  def is_collectible?(%File{software_type: :virus_spam}),
    do: reply_ok()
  def is_collectible?(%File{software_type: :virus_miner}),
    do: reply_ok()
  def is_collectible?(%File{}),
    do: reply_error({:virus, :not_collectible})
end
