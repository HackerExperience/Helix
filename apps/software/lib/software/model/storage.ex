defmodule HELM.Software.Model.Storage do
  use Ecto.Schema
  import Ecto.Changeset

  alias HELL.UUID, as: HUUID
  alias HELM.Software.Model.StorageDrive, as: MdlStorageDrive, warn: false
  alias HELM.Software.Model.File, as: MdlFile, warn: false

  @primary_key {:storage_id, :binary_id, autogenerate: false}

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
    |> put_uuid()
  end

  defp put_uuid(changeset) do
    if changeset.valid?,
      do: put_change(changeset, :storage_id, uuid()),
      else: changeset
  end

  defp uuid,
    do: HUUID.create!("06", meta1: "1")
end