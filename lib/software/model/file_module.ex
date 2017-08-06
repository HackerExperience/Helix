defmodule Helix.Software.Model.FileModule do

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias HELL.Constant
  alias Helix.Software.Model.File
  alias Helix.Software.Model.SoftwareModule

  @type t :: %__MODULE__{
    module_version: pos_integer,
    file: File.t,
    file_id: File.id,
    software_module: Constant.t
  }

  @type creation_params :: %{
    file_id: File.id,
    software_module: Constant.t,
    module_version: pos_integer
  }
  @type update_params :: %{
    module_version: pos_integer
  }

  @creation_fields ~w/file_id software_module module_version/a
  @update_fields ~w/module_version/a

  @primary_key false
  schema "file_modules" do
    field :file_id, File.ID,
      primary_key: true
    field :software_module, Constant,
      primary_key: true
    field :module_version, :integer

    belongs_to :file, File,
      foreign_key: :file_id,
      references: :file_id,
      define_field: false,
      on_replace: :update
  end

  @spec create_changeset(creation_params) ::
    Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required([:file_id, :software_module, :module_version])
    |> generic_validations()
  end

  @spec update_changeset(t | Changeset.t, update_params) ::
    Changeset.t
  def update_changeset(schema, params) do
    schema
    |> cast(params, @update_fields)
    |> generic_validations()
  end

  @spec generic_validations(Changeset.t) ::
    Changeset.t
  def generic_validations(changeset) do
    changeset
    |> validate_number(:module_version, greater_than: 0)
    |> validate_inclusion(:software_module, SoftwareModule.possible_modules())
  end

  @spec changeset(t | Changeset.t, creation_params) ::
    Changeset.t
  def changeset(struct, params) do
    struct
    |> cast(params, @creation_fields)
    |> validate_required([:software_module, :module_version])
    |> generic_validations()
  end

  defmodule Query do
    import Ecto.Query

    alias Ecto.Queryable
    alias HELL.Constant
    alias Helix.Software.Model.File
    alias Helix.Software.Model.FileModule

    @spec by_file(Queryable.t, File.idtb) ::
      Queryable.t
    def by_file(query \\ FileModule, id),
      do: where(query, [fm], fm.file_id == ^id)

    @spec by_software_module(Queryable.t, Constant.t) ::
      Queryable.t
    def by_software_module(query \\ FileModule, software_module),
      do: where(query, [fm], fm.software_module == ^software_module)
  end
end
