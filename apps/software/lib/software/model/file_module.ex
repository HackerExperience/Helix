defmodule Helix.Software.Model.FileModule do

  use Ecto.Schema

  alias HELL.PK
  alias Helix.Software.Model.File
  alias Helix.Software.Model.ModuleRole

  import Ecto.Changeset

  @type t :: %__MODULE__{
    module_version: non_neg_integer,
    file: File.t,
    file_id: PK.t,
    role: ModuleRole.t,
    module_role_id: PK.t
  }

  @type creation_params :: %{
    file_id: PK.t,
    module_role_id: PK.t,
    module_version: non_neg_integer
  }
  @type update_params :: %{module_version: non_neg_integer}

  @creation_fields ~w/file_id module_role_id module_version/a
  @update_fields ~w/module_version/a

  @primary_key false
  schema "file_modules" do
    belongs_to :file, File,
      foreign_key: :file_id,
      references: :file_id,
      type: HELL.PK,
      primary_key: true
    belongs_to :role, ModuleRole,
      foreign_key: :module_role_id,
      references: :module_role_id,
      type: HELL.PK,
      primary_key: true

    field :module_version, :integer
  end

  @spec create_changeset(creation_params) :: Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required([:file_id, :module_role_id, :module_version])
    |> generic_validations()
  end

  @spec update_changeset(t | Ecto.Changeset.t, update_params) :: Ecto.Changeset.t
  def update_changeset(schema, params) do
    schema
    |> cast(params, @update_fields)
    |> generic_validations()
  end

  @spec generic_validations(Ecto.Changeset.t) :: Ecto.Changeset.t
  def generic_validations(changeset) do
    changeset
    |> validate_number(:module_version, greater_than: 0)
  end

  defmodule Query do

    alias Helix.Software.Model.FileModule

    import Ecto.Query, only: [where: 3, select: 3]

    @spec from_file(HELL.PK.t) :: Ecto.Queryable.t
    @spec from_file(Ecto.Queryable.t, HELL.PK.t) :: Ecto.Queryable.t
    def from_file(query \\ FileModule, file_id),
      do: where(query, [fm], fm.file_id == ^file_id)

    @spec by_module_role_id(HELL.PK.t) :: Ecto.Queryable.t
    @spec by_module_role_id(Ecto.Queryable.t, HELL.PK.t) :: Ecto.Queryable.t
    def by_module_role_id(query \\ FileModule, module_role_id),
      do: where(query, [fm], fm.module_role_id == ^module_role_id)

    @spec select_module_role_id_and_module_version() :: Ecto.Queryable.t
    @spec select_module_role_id_and_module_version(Ecto.Queryable.t) ::
      Ecto.Queryable.t
    def select_module_role_id_and_module_version(query \\ FileModule),
      do: select(query, [fm], {fm.module_role_id, fm.module_version})
  end
end