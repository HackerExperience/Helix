defmodule HELM.Software.Model.Storage do
  use Ecto.Schema
  import Ecto.Changeset

  alias HELL.IPv6
  alias HELM.Software.Model.StorageDrive, as: MdlStorageDrive, warn: false
  alias HELM.Software.Model.File, as: MdlFile, warn: false

  @primary_key {:storage_id, EctoNetwork.INET, autogenerate: false}

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
    |> put_primary_key()
  end

  defp put_primary_key(changeset) do
    ip = IPv6.generate([0x0004, 0x0001, 0x0000])

    changeset
    |> cast(%{storage_id: ip}, ~w(storage_id))
  end
end