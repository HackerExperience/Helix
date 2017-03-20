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

  @creation_fields ~w/storage_id/a

  @primary_key false
  @ecto_autogenerate {:drive_id, {PK, :pk_for, [__MODULE__]}}
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
    |> validate_required(@creation_fields)
  end
end