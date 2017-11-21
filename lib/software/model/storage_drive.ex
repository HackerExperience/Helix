defmodule Helix.Software.Model.StorageDrive do

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias Helix.Server.Model.Component
  alias Helix.Software.Model.Storage

  @type t :: %__MODULE__{
    storage_id: Storage.id,
    drive_id: Component.id,
    storage: term
  }

  @type creation_params :: %{
    storage_id: Storage.id,
    drive_id: Component.id
  }

  @creation_fields ~w/storage_id drive_id/a

  @primary_key false
  schema "storage_drives" do
    field :storage_id, Storage.ID,
      primary_key: true
    field :drive_id, Component.ID,
      primary_key: true

    belongs_to :storage, Storage,
      foreign_key: :storage_id,
      references: :storage_id,
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
    import Ecto.Query

    alias Ecto.Queryable
    alias Helix.Hardware.Model.Component
    alias Helix.Software.Model.Storage
    alias Helix.Software.Model.StorageDrive

    @spec by_storage(Queryable.t, Storage.idtb) ::
      Queryable.t
    def by_storage(query \\ StorageDrive, id),
      do: where(query, [sd], sd.storage_id == ^id)

    @spec by_drive(Queryable.t, Component.idtb) ::
      Queryable.t
    def by_drive(query \\ StorageDrive, id),
      do: where(query, [sd], sd.drive_id == ^id)

    @spec select_drive_id(Queryable.t) ::
      Queryable.t
    def select_drive_id(query),
      do: select(query, [sd], sd.drive_id)
  end
end
