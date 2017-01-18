defmodule Helix.Software.Model.File do

  use Ecto.Schema

  alias HELL.PK
  alias Helix.Software.Model.FileType
  alias Helix.Software.Model.Storage

  import Ecto.Changeset

  @type t :: %__MODULE__{
    file_id: PK.t,
    name: String.t,
    file_path: String.t,
    file_size: pos_integer,
    type: FileType.t,
    file_type: String.t,
    storage: Storage.t,
    storage_id: PK.t,
    inserted_at: NaiveDateTime.t,
    updated_at: NaiveDateTime.t
  }

  @type creation_params :: %{
    name: String.t,
    file_path: String.t,
    file_size: pos_integer,
    file_type: String.t,
    storage_id: PK.t
  }
  @type update_params :: %{
    name: String.t,
    file_path: String.t,
    storage_id: PK.t
  }

  @creation_fields ~w/name file_path file_size file_type storage_id/a
  @update_fields ~w/name file_path storage_id/a

  @primary_key false
  schema "files" do
    field :file_id, HELL.PK,
      primary_key: true

    field :name, :string
    field :file_path, :string
    field :file_size, :integer

    belongs_to :type, FileType,
      foreign_key: :file_type,
      references: :file_type,
      type: :string
    belongs_to :storage, Storage,
      foreign_key: :storage_id,
      references: :storage_id,
      type: HELL.PK

    timestamps()
  end

  @spec create_changeset(creation_params) :: Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> generic_validations()
    |> put_primary_key()
  end

  @spec update_changeset(t | Ecto.Changeset.t, update_params) :: Ecto.Changeset.t
  def update_changeset(model, params) do
    model
    |> cast(params, @update_fields)
    |> generic_validations()
  end

  @spec generic_validations(Ecto.Changeset.t) :: Ecto.Changeset.t
  defp generic_validations(changeset) do
    changeset
    |> validate_required(
      [:name, :file_path, :file_size, :file_type, :storage_id])
    |> validate_number(:file_size, greater_than: 0)
  end

  @spec put_primary_key(Ecto.Changeset.t) :: Ecto.Changeset.t
  defp put_primary_key(changeset) do
    ip = PK.generate([0x0004, 0x0000, 0x0000])

    changeset
    |> cast(%{file_id: ip}, [:file_id])
  end
end