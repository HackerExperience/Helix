defmodule Helix.Software.Model.Virus do
  @moduledoc """
  The `Virus` model maps all virus installations, telling us which entity
  installed the virus.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import HELL.Ecto.Macros

  alias Ecto.Changeset
  alias Helix.Entity.Model.Entity
  alias Helix.Universe.Bank.Model.BankAccount
  alias Helix.Software.Model.Software
  alias Helix.Software.Model.File
  alias __MODULE__, as: Virus

  @type t ::
    %__MODULE__{
      file_id: File.id,
      entity_id: Entity.id,
      is_active?: boolean,
      running_time: seconds :: integer | nil
    }

  @typep wallet :: term

  @type payment_info ::
    {BankAccount.t, wallet}
    | {nil, wallet}
    | {BankAccount.t, nil}

  @type earnings :: BankAccount.amount | float

  @type changeset :: %Changeset{data: %__MODULE__{}}
  @type id :: File.id

  @type creation_params ::
    %{
      file_id: File.id,
      entity_id: Entity.id
    }

  @creation_fields [:file_id, :entity_id]
  @required_fields [:file_id, :entity_id]

  @primary_key false
  schema "viruses" do
    field :file_id, File.ID,
      primary_key: true

    field :entity_id, Entity.ID

    field :is_active?, :boolean,
      virtual: true,
      default: false

    # Time (in seconds) the virus has been running. Only set when active.
    field :running_time, :integer,
      virtual: true,
      default: nil

    has_one :active, Virus.Active,
      foreign_key: :virus_id,
      references: :file_id

    belongs_to :file, File,
      references: :file_id,
      foreign_key: :file_id,
      define_field: false
  end

  @spec create_changeset(creation_params) ::
    changeset
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(@required_fields)
  end

  @spec format(t) ::
    t
  @doc """
  Formats the fetched virus, including information about its `active` status.
  """
  def format(virus = %Virus{}) do
    {is_active?, running_time} =
      if not is_nil(virus.active) and Ecto.assoc_loaded?(virus.active) do
        time = DateTime.diff(DateTime.utc_now(), virus.active.activation_time)

        {true, time}
      else
        {false, nil}
      end

    %{virus|
      is_active?: is_active?,
      running_time: running_time,

      # `active` assoc is, from the VirusInternal above, implementation detail.
      active: nil}
  end

  @spec calculate_earnings(Software.virus, t, list) ::
    earnings
  @doc """
  Calculates the earnings of the given viruses based on its type, previous
  earnings etc. All of the game balance math is delegated to `Helix.Balance`.
  """
  def calculate_earnings(
    _virus_type, _virus = %Virus{is_active?: true}, _saved_earnings)
  do
    # Obviously TODO #389
    5000
  end

  query do

    alias Helix.Entity.Model.Entity
    alias Helix.Software.Model.File
    alias Helix.Software.Model.Storage

    @spec by_file(Queryable.t, File.id) ::
      Queryable.t
    def by_file(query \\ Virus, file_id),
      do: where(query, [v], v.file_id == ^file_id)

    @spec by_entity(Queryable.t, Entity.idt) ::
      Queryable.t
    def by_entity(query \\ Virus, entity_id),
      do: where(query, [v], v.entity_id == ^entity_id)

    @spec by_storage(Queryable.t, Storage.idt) ::
      Queryable.t
    def by_storage(query \\ Virus, storage_id) do
      from virus in query,
        inner_join: file in assoc(virus, :file),
        where: file.storage_id == ^storage_id,
        select: virus
    end

    @spec by_storage_and_entity(Queryable.t, Storage.idt, Entity.idt) ::
      Queryable.t
    def by_storage_and_entity(query \\ Virus, storage_id, entity_id) do
      from virus in query,
        inner_join: file in assoc(virus, :file),
        where: file.storage_id == ^storage_id,
        where: virus.entity_id == ^entity_id,
        select: virus
    end

    @spec join_active(Queryable.t) ::
      Queryable.t
    def join_active(query) do
      query
      |> join(:left, [v], va in assoc(v, :active))
      |> preload_active()
    end

    @spec preload_active(Queryable.t) ::
      Queryable.t
    defp preload_active(query),
      do: preload(query, [..., va], [active: va])
  end
end
