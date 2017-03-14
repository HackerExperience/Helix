defmodule Helix.Software.Model.StorageDrive do

  use Ecto.Schema

  alias HELL.PK
  alias Helix.Software.Model.Storage

  import Ecto.Changeset

  @type t :: %__MODULE__{
    storage_id: PK.t,
    storage: Storage.t,
    drive_id: PK.t
  }

  @type creation_params :: %{storage_id: PK.t}

  @creation_fields ~w/storage_id/a

  @primary_key false
  schema "storage_drives" do
    field :storage_id, PK,
      primary_key: true
    field :drive_id, PK,
      primary_key: true

    belongs_to :storage, Storage,
      foreign_key: :storage_id,
      references: :storage_id,
      type: HELL.PK,
      define_field: false
  end

  @spec create_changeset(%{storage_id: PK.t}) :: Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> put_primary_key()
    |> validate_required(@creation_fields)
    |> foreign_key_constraint(:storage_id)
  end

  @spec put_primary_key(Ecto.Changeset.t) :: Ecto.Changeset.t
  defp put_primary_key(changeset) do
    if get_field(changeset, :drive_id) do
      changeset
    else
      pk = PK.generate([0x0004, 0x0001, 0x0001])
      put_change(changeset, :drive_id, pk)
    end
  end

  defmodule Query do

    alias HELL.PK
    alias Helix.Software.Model.Storage
    alias Helix.Software.Model.StorageDrive

    import Ecto.Query, only: [where: 3]

    @spec from_storage(Ecto.Queryable.t, Storage.t | PK.t) :: Ecto.Queryable.t
    def from_storage(query \\ StorageDrive, storage_or_storage_id)
    def from_storage(query, storage = %Storage{}),
      do: from_storage(query, storage.storage_id)
    def from_storage(query, storage_id),
      do: where(query, [sd], sd.storage_id == ^storage_id)

    @spec by_drive_id(Ecto.Queryable.t, PK.t) :: Ecto.Queryable.t
    def by_drive_id(query \\ StorageDrive, drive_id),
      do: where(query, [sd], sd.drive_id == ^drive_id)
  end
end