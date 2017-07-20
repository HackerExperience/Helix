defmodule Helix.Software.Model.StorageDrive do

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias HELL.PK
  alias Helix.Hardware.Model.Component
  alias Helix.Software.Model.Storage


  @type t :: %__MODULE__{
    storage_id: Storage.id,
    storage: Storage.t,
    drive_id: Component.id
  }

  @type creation_params :: %{
    storage_id: Storage.id,
    drive_id: Component.id
  }

  @creation_fields ~w/storage_id drive_id/a

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

  @spec create_changeset(creation_params) ::
    Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(@creation_fields)
    |> foreign_key_constraint(:storage_id)
  end

  defmodule Query do

    import Ecto.Query, only: [where: 3]

    alias Ecto.Queryable
    alias Helix.Hardware.Model.Component
    alias Helix.Software.Model.Storage
    alias Helix.Software.Model.StorageDrive

    @spec from_storage(Queryable.t, Storage.t | Storage.id) ::
      Queryable.t
    def from_storage(query \\ StorageDrive, storage_or_storage_id)
    def from_storage(query, storage = %Storage{}),
      do: from_storage(query, storage.storage_id)
    def from_storage(query, storage_id),
      do: where(query, [sd], sd.storage_id == ^storage_id)

    @spec by_drive_id(Queryable.t, Component.id) ::
      Queryable.t
    def by_drive_id(query \\ StorageDrive, drive_id),
      do: where(query, [sd], sd.drive_id == ^drive_id)
  end
end
