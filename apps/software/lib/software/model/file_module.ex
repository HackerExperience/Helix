defmodule Helix.Software.Model.FileModule do

  use Ecto.Schema

  alias HELL.PK
  alias Helix.Software.Model.File
  alias Helix.Software.Model.SoftwareModule

  import Ecto.Changeset

  @type t :: %__MODULE__{
    module_version: pos_integer,
    file: File.t,
    file_id: PK.t,
    software_module: SoftwareModule.t,
    software_module_id: PK.t
  }

  @type creation_params :: %{
    file_id: PK.t,
    software_module_id: PK.t,
    module_version: pos_integer
  }
  @type update_params :: %{module_version: pos_integer}

  @creation_fields ~w/file_id software_module_id module_version/a
  @update_fields ~w/module_version/a

  @primary_key false
  schema "file_modules" do
    belongs_to :file, File,
      foreign_key: :file_id,
      references: :file_id,
      type: HELL.PK,
      primary_key: true
    belongs_to :software_module, SoftwareModule,
      foreign_key: :software_module_id,
      references: :software_module_id,
      type: HELL.PK,
      primary_key: true

    field :module_version, :integer
  end

  @spec create_changeset(creation_params) :: Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required([:file_id, :software_module_id, :module_version])
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

    alias Helix.Software.Model.File
    alias Helix.Software.Model.FileModule

    import Ecto.Query, only: [where: 3, select: 3]

    @spec from_file(File.t | HELL.PK.t) :: Ecto.Queryable.t
    def from_file(file_or_file_id),
      do: from_file(FileModule, file_or_file_id)

    @spec from_file(Ecto.Queryable.t, File.t | HELL.PK.t) :: Ecto.Queryable.t
    def from_file(query, file = %File{}),
      do: from_file(query, file.file_id)
    def from_file(query, file_id),
      do: where(query, [fm], fm.file_id == ^file_id)

    @spec by_software_module_id(HELL.PK.t) :: Ecto.Queryable.t
    @spec by_software_module_id(Ecto.Queryable.t, HELL.PK.t) :: Ecto.Queryable.t
    def by_software_module_id(query \\ FileModule, software_module_id),
      do: where(query, [fm], fm.software_module_id == ^software_module_id)
  end
end