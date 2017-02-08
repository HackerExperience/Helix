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
  def create_changeset do
    %__MODULE__{}
    |> cast(%{}, [])
    |> put_primary_key()
  end

  @spec put_primary_key(Ecto.Changeset.t) :: Ecto.Changeset.t
  defp put_primary_key(changeset) do
    if get_field(changeset, :storage_id) do
      changeset
    else
      pk = PK.generate([0x0004, 0x0001, 0x0000])
      put_change(changeset, :storage_id, pk)
    end
  end
end