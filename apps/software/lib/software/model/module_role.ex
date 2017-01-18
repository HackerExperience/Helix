defmodule Helix.Software.Model.ModuleRole do

  use Ecto.Schema

  alias HELL.PK
  alias Helix.Software.Model.FileType
  import Ecto.Changeset

  @type t :: %__MODULE__{
    module_role_id: PK.t,
    module_role: String.t,
    type: FileType.t
  }

  @creation_fields ~w/file_type module_role/a

  @primary_key false
  schema "module_roles" do
    field :module_role_id, HELL.PK,
      primary_key: true

    field :module_role, :string

    # FIXME: this name must change soon
    belongs_to :type, FileType,
      foreign_key: :file_type,
      references: :file_type,
      type: :string
  end

  @spec create_changeset(%{file_type: String.t, module_role: String.t}) :: Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required([:module_role, :file_type])
    |> unique_constraint(:module_role, name: :file_type_module_role_unique_constraint)
    |> put_primary_key()
  end

  @spec put_primary_key(Ecto.Changeset.t) :: Ecto.Changeset.t
  defp put_primary_key(changeset) do
    pk = PK.generate([0x0004, 0x0002, 0x0000])

    changeset
    |> cast(%{module_role_id: pk}, [:module_role_id])
  end
end