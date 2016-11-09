defmodule HELM.Software.Model.StorageDrive do
  use Ecto.Schema
  import Ecto.Changeset

  alias HELM.Software.Model.Storage, as: MdlStorage, warn: false

  @primary_key false
  @creation_fields ~w/drive_id storage_id/a

  schema "storage_drives" do
    belongs_to :storage, MdlStorage,
      foreign_key: :storage_id,
      references: :storage_id,
      type: EctoNetwork.INET,
      primary_key: true

    field :drive_id, :integer, primary_key: true

    timestamps
  end

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> unique_constraint(:storage_id)
  end
end