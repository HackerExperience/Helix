defmodule Helix.Software.Model.StorageDrive do

  use Ecto.Schema

  alias HELL.PK
  alias Helix.Software.Model.Storage

  import Ecto.Changeset

  @type t :: %__MODULE__{
    storage_id: PK.t,
    storage: Storage.t,
    drive_id: integer,
    hardware_id: PK.t
  }

  @creation_fields ~w/drive_id hardware_id storage_id/a

  @primary_key false
  schema "storage_drives" do
    field :storage_id, PK,
      primary_key: true
    field :drive_id, :integer,
      primary_key: true

    field :hardware_id, PK

    belongs_to :storage, Storage,
      foreign_key: :storage_id,
      references: :storage_id,
      type: HELL.PK,
      define_field: false
  end

  @spec create_changeset(%{drive_id: PK.t, storage_id: PK.t, hardware_id: PK.t}) :: Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(@creation_fields)
  end
end