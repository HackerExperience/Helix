defmodule Helix.Software.Model.Storage do

  use Ecto.Schema

  alias HELL.PK
  alias Helix.Software.Model.File
  alias Helix.Software.Model.StorageDrive

  import Ecto.Changeset

  @type t :: %__MODULE__{
    storage_id: PK.t,
    drives: [StorageDrive.t],
    files: [File.t]
  }

  @primary_key false
  @ecto_autogenerate {:storage_id, {PK, :pk_for, [:software_storage]}}
  schema "storages" do
    field :storage_id, HELL.PK,
      primary_key: true

    has_many :drives, StorageDrive,
      foreign_key: :storage_id,
      references: :storage_id
    has_many :files, File,
      foreign_key: :storage_id,
      references: :storage_id
  end

  @spec create_changeset() :: Ecto.Changeset.t
  def create_changeset,
    do: cast(%__MODULE__{}, %{}, [])
end
