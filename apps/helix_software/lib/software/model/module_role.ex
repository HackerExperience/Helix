defmodule Helix.Software.Model.ModuleRole do

  use Ecto.Schema

  alias HELL.PK
  alias Helix.Software.Model.SoftwareType

  import Ecto.Changeset

  @type t :: %__MODULE__{
    module_role_id: PK.t,
    module_role: String.t,
    type: SoftwareType.t
  }

  @creation_fields ~w/software_type module_role/a

  @primary_key false
  @ecto_autogenerate {:module_role_id, {PK, :pk_for, [__MODULE__]}}
  schema "module_roles" do
    field :module_role_id, HELL.PK,
      primary_key: true

    field :module_role, :string

    # FIXME: this name must change soon
    belongs_to :type, SoftwareType,
      foreign_key: :software_type,
      references: :software_type,
      type: :string
  end

  @spec create_changeset(%{software_type: String.t, module_role: String.t}) ::
    Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required([:module_role, :software_type])
    |> unique_constraint(:module_role,
      name: :module_roles_module_role_software_type_index)
  end

  defmodule Query do

    alias Helix.Software.Model.ModuleRole

    import Ecto.Query, only: [where: 3]

    @spec by_software_type(String.t) :: Ecto.Queryable.t
    @spec by_software_type(Ecto.Queryable.t, String.t) :: Ecto.Queryable.t
    def by_software_type(query \\ ModuleRole, software_type),
      do: where(query, [m], m.software_type == ^software_type)
  end
end
