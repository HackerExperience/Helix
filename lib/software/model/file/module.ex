defmodule Helix.Software.Model.File.Module do
  @moduledoc """
  A File.Module is a component of a File responsible for doing something. It
  contains a version, which is a representation of how powerful that module is.

  For example, take the Cracker. It may have Overflow and Bruteforce modules.
  `Cracker` is a Software.Type, and `Overflow` and `Bruteforce` are
  `Software.Module`s.

  An instance of a Cracker is said to be a File, and the representation of each
  File's modules are called `File.Module`s.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias HELL.Constant
  alias Helix.Software.Model.File
  alias Helix.Software.Model.Software
  alias __MODULE__, as: Module

  @type t :: %{
    name => Module.Data.t
  }

  @type schema :: %__MODULE__{
    version: pos_integer,
    file: File.t,
    file_id: File.id,
    name: name
  }

  @type name :: Software.module_name
  @type version :: pos_integer

  @type changeset :: %Changeset{data: %__MODULE__{}}

  @type creation_params :: %{
    name: name,
    version: version
  }

  @type update_params :: %{
    version: version
  }

  @creation_fields ~w/name version/a
  @update_fields ~w/version/a
  @required_fields ~w/name version/a

  @primary_key false
  schema "file_modules" do
    field :file_id, File.ID,
      primary_key: true
    field :name, Constant,
      primary_key: true
    field :version, :integer

    belongs_to :file, File,
      foreign_key: :file_id,
      references: :file_id,
      define_field: false,
      on_replace: :update
  end

  @spec create_changeset(creation_params) ::
    changeset
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(@required_fields)
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
    |> validate_number(:version, greater_than: 0)
    |> validate_inclusion(:name, Software.Module.all())
  end

  @spec format(schema) ::
    t
  @doc """
  Formats a FileModule 
  """
  def format(module = %__MODULE__{}) do
    data = Module.Data.new(module)

    Map.put(%{}, module.name, data)
  end

  defmodule Data do
    @moduledoc """
    FileModuleData contains information about the corresponding module.
    """

    alias Helix.Software.Model.File

    @type t ::
      %__MODULE__{
        version: File.Module.version
      }

    @enforce_keys [:name, :version]
    defstruct [:name, :version]

    @spec new(
      File.Module.schema
      | %{name: File.Module.name, version: File.Module.version})
    ::
      t
    def new(%{name: name, version: version}) do
      %__MODULE__{
        name: name,
        version: version
      }
    end
  end

  defmodule Query do

    import Ecto.Query

    alias Ecto.Queryable
    alias HELL.Constant
    alias Helix.Software.Model.File

    @spec by_file(Queryable.t, File.idtb) ::
      Queryable.t
    def by_file(query \\ File.Module, id),
      do: where(query, [fm], fm.file_id == ^id)

    @spec by_name(Queryable.t, Constant.t) ::
      Queryable.t
    def by_name(query \\ File.Module, name),
      do: where(query, [fm], fm.name == ^name)
  end
end
