defmodule HELM.Software.Storage.Schema do
  use Ecto.Schema

  import Ecto.Changeset
  alias Ecto.Changeset
  alias HELM.Software.Storage.Schema, as: SoftStorageSchema

  @primary_key {:storage_id, :string, autogenerate: false}

  schema "storages" do
    has_many :drives, SoftStorageSchema,
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
