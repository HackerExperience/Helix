defmodule HELM.Software.Storage.Drive.Schema do
  use Ecto.Schema

  import Ecto.Changeset

  alias HELM.Software.Storage.Schema, as: SoftStorageSchema
  alias Ecto.Changeset

  @primary_key {:drive_id, :integer, autogenerate: false}
  @creation_fields ~w/drive_id storage_id/a

  schema "storage_drives" do
    belongs_to :storages, SoftStorageSchema,
      foreign_key: :storage_id,
      references: :storage_id,
      type: :string

    timestamps
  end

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> unique_constraint(:storage_id)
  end
end
