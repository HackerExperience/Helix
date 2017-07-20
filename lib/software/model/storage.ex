defmodule Helix.Software.Model.Storage do

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias HELL.PK
  alias Helix.Software.Model.File
  alias Helix.Software.Model.StorageDrive


  @type id :: PK.t
  @type t :: %__MODULE__{
    storage_id: id,
    drives: [StorageDrive.t],
    files: [File.t]
  }

  @primary_key false
  @ecto_autogenerate {:storage_id, {PK, :pk_for, [:software_storage]}}
  schema "storages" do
    field :storage_id, PK,
      primary_key: true

    has_many :drives, StorageDrive,
      foreign_key: :storage_id,
      references: :storage_id
    has_many :files, File,
      foreign_key: :storage_id,
      references: :storage_id
  end

  @spec create_changeset() ::
    Changeset.t
  def create_changeset,
    do: cast(%__MODULE__{}, %{}, [])
end
