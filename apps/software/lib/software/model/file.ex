defmodule HELM.Software.Model.File do
  use Ecto.Schema
  import Ecto.Changeset

  alias HELL.IPv6
  alias HELM.Software.Model.FileType, as: MdlFileType, warn: false
  alias HELM.Software.Model.Storage, as: MdlStorage, warn: false

  @primary_key {:file_id, EctoNetwork.INET, autogenerate: false}
  @creation_fields ~w/name file_path file_size file_type storage_id/a
  @update_fields ~w/name file_path storage_id/a

  schema "files" do
    field :name, :string
    field :file_path, :string
    field :file_size, :integer

    belongs_to :type, MdlFileType,
      foreign_key: :file_type,
      references: :file_type,
      type: :string

    belongs_to :storage, MdlStorage,
      foreign_key: :storage_id,
      references: :storage_id,
      type: EctoNetwork.INET

    timestamps
  end

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_number(:file_size, greater_than: 0)
    |> put_primary_key()
  end

  def update_changeset(model, params) do
    model
    |> cast(params, @update_fields)
  end

  defp put_primary_key(changeset) do
    ip = IPv6.generate([0x0004, 0x0000, 0x0000])

    changeset
    |> cast(%{file_id: ip}, ~w/file_id/a)
  end
end