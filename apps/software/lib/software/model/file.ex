defmodule HELM.Software.Model.File do
  use Ecto.Schema
  import Ecto.Changeset

  alias HELL.UUID, as: HUUID
  alias HELM.Software.Model.FileType, as: MdlFileType, warn: false
  alias HELM.Software.Model.Storage, as: MdlStorage, warn: false

  @primary_key {:file_id, :binary_id, autogenerate: false}
  @creation_fields ~w/name file_path file_size file_type storage_id/a
  @update_fields ~w/name file_path storage_id/a

  schema "files" do
    field :name, :string
    field :file_path, :string
    field :file_size, :integer

    belongs_to :file_type_entity, MdlFileType,
      foreign_key: :file_type,
      references: :file_type,
      type: :string

    belongs_to :storage_entity, MdlStorage,
      foreign_key: :storage_id,
      references: :storage_id,
      type: :binary_id

    timestamps
  end

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_number(:file_size, greater_than: 0)
    |> put_uuid
  end

  def update_changeset(model, params) do
    model
    |> cast(params, @update_fields)
  end

  defp put_uuid(changeset) do
    if changeset.valid?,
      do: put_change(changeset, :file_id, uuid()),
      else: changeset
  end

  defp uuid,
    do: HUUID.create!("06", meta1: "0")
end