defmodule HELM.Software.Model.File do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.Changeset

  alias HELM.Software.Model.FileType, as: MdlFileType, warn: false
  alias HELM.Software.Model.Storage, as: MdlStorage, warn: false

  @primary_key {:file_id, :string, autogenerate: false}
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
      type: :string

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
    if changeset.valid? do
      file_id = HELL.ID.generate("FILE")
      Changeset.put_change(changeset, :file_id, file_id)
    else
      changeset
    end
  end
end