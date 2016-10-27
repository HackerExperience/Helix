defmodule HELM.Software.Model.Storage do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.Changeset

  alias HELM.Software.Model.StorageDrive, as: MdlStorageDrive, warn: false
  alias HELM.Software.Model.File, as: MdlFile, warn: false

  @primary_key {:storage_id, :string, autogenerate: false}

  schema "storages" do
    has_many :drives, MdlStorageDrive,
      foreign_key: :storage_id,
      references: :storage_id

    has_many :files, MdlFile,
      foreign_key: :storage_id,
      references: :storage_id

    timestamps
  end

  def create_changeset do
    %__MODULE__{}
    |> cast(%{}, [])
    |> put_uuid
  end

  defp put_uuid(changeset) do
    if changeset.valid? do
      storage_id = HELL.ID.generate("STRG")
      Changeset.put_change(changeset, :storage_id, storage_id)
    else
      changeset
    end
  end
end