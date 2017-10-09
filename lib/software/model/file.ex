defmodule Helix.Software.Model.File do

  use Ecto.Schema
  use HELL.ID, field: :file_id, meta: [0x0020]

  import Ecto.Changeset
  import HELL.Macros

  alias Ecto.Changeset
  alias HELL.Constant
  alias Helix.Software.Model.FileModule
  alias Helix.Software.Model.SoftwareType
  alias Helix.Software.Model.Storage

  @type t :: t_of_type(SoftwareType.type)

  @type t_of_type(type) :: %__MODULE__{
    file_id: id,
    name: name,
    path: path,
    full_path: full_path,
    file_size: size,
    type: SoftwareType.t,
    software_type: type,
    storage_id: Storage.id,
    storage: term,
    inserted_at: NaiveDateTime.t,
    updated_at: NaiveDateTime.t,
    modules: FileModule.t | FileModule.schema,
    crypto_version: crypto_version
  }

  @type path :: String.t
  @type full_path :: path
  @type name :: String.t
  @type size :: pos_integer
  @type type :: SoftwareType.type
  @type crypto_version :: nil | pos_integer

  @type changeset :: %Changeset{data: %__MODULE__{}}

  @type creation_params :: %{
    name: name,
    path: path,
    file_size: size,
    software_type: SoftwareType.type,
    storage_id: Storage.idtb
  }

  @type modules_params :: [{FileModule.name, FileModule.Data.t}]

  @type update_params :: %{
    optional(:name) => name,
    optional(:path) => path,
    optional(:crypto_version) => non_neg_integer | nil
  }

  @creation_fields ~w/name path storage_id file_size software_type/a
  @update_fields ~w/crypto_version/a
  @castable_fields ~w/name path/a

  @required_fields ~w/name path file_size software_type storage_id/a

  @software_types Map.keys(SoftwareType.possible_types())

  schema "files" do
    field :file_id, ID,
      primary_key: true

    field :name, :string
    field :path, :string
    field :software_type, Constant
    field :file_size, :integer
    field :storage_id, Storage.ID

    field :crypto_version, :integer

    field :full_path, :string

    belongs_to :type, SoftwareType,
      foreign_key: :software_type,
      references: :software_type,
      define_field: false
    belongs_to :storage, Storage,
      foreign_key: :storage_id,
      references: :storage_id,
      define_field: false

    has_many :modules, FileModule,
      foreign_key: :file_id,
      references: :file_id,
      on_replace: :delete

    timestamps()
  end

  @spec create_changeset(creation_params, modules_params) ::
    changeset
  @doc """
  Creates the `File` changeset, as well as its modules' associations.
  """
  def create_changeset(params, modules_params) do
    modules = Enum.map(modules_params, &create_module_assoc/1)

    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> put_assoc(:modules, modules)
    |> validate_changeset(params)
  end

  # TODO: Used internally by cryptokey model. Use another name / refactor
  @spec create(Storage.t, map) ::
    Changeset.t
  def create(storage = %Storage{}, params) do
    IO.puts "DEPRECATED"
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> put_assoc(:storage, storage)
    |> validate_changeset(params)
  end

  @spec format(t) ::
    t
  @doc """
  Formats the given `File`. Most notably, this function makes the File.Modules
  interface more friendly.
  """
  def format(file) do
    formatted_modules =
      Enum.reduce(file.modules, %{}, fn module, acc ->
        module = FileModule.format(module)
        Map.merge(acc, module)
      end)

    %{file| modules: formatted_modules}
  end

  def update_crypto_version(struct, version) do
    struct
    |> cast(%{crypto_version: version}, [:crypto_version])
    |> put_change(:crypto_version, version)
    |> validate_changeset(%{})
    |> validate_number(:crypto_version, greater_than: 0)
  end

  @spec update_changeset(t | Changeset.t, update_params) ::
    Changeset.t
  def update_changeset(struct, params) do
    struct
    |> cast(params, @update_fields)
    |> validate_changeset(params)
    |> validate_number(:crypto_version, greater_than: 0)
  end

  defp validate_changeset(struct, params) do
    struct
    |> cast(params, @castable_fields)
    |> validate_required(@required_fields)
    |> validate_number(:file_size, greater_than: 0)
    |> validate_inclusion(:software_type, @software_types)
    |> unique_constraint(:full_path, name: :files_storage_id_full_path_index)
    |> update_change(:path, &add_leading_slash/1)
    |> update_change(:path, &remove_trailing_slash/1)
    |> prepare_changes(&update_full_path/1)
  end

  @spec create_module_assoc(modules_params) ::
    FileModule.changeset
  docp """
  Helper/wrapper to `FileModule.create_changeset/1`
  """
  defp create_module_assoc({name, data}) do
    params = %{
      name: name,
      version: data.version
    }

    FileModule.create_changeset(params)
  end

  docp """
  Path: Path from root dir (`/`) to file directory
  Full path: `path` + `File.name` + `File.extension`
  """
  defp update_full_path(changeset) do
    path = get_field(changeset, :path)
    name = get_field(changeset, :name)
    software_type = get_field(changeset, :software_type)
    extension = SoftwareType.possible_types()[software_type].extension

    full_path = path <> "/" <> name <> "." <> extension

    put_change(changeset, :full_path, full_path)
  end

  defp add_leading_slash(path = "/" <> _),
    do: path
  defp add_leading_slash(path),
    do: "/" <> path

  docp """
  Removes the trailing slash of a path, if any. Does not apply when "/" is the
  actual path.
  """
  defp remove_trailing_slash(path) do
    path_size = (byte_size(path) - 1) * 8

    case path do
      <<path::bits-size(path_size)>> <> "/" ->
        <<path::bits-size(path_size)>>
      path ->
        path
    end
  end

  defmodule Query do

    import Ecto.Query
    import HELL.Macros

    alias Ecto.Queryable
    alias Helix.Software.Model.File
    alias Helix.Software.Model.Storage

    @spec by_file(Queryable.t, File.idtb) ::
      Queryable.t
    def by_file(query \\ File, id) do
      query
      |> where([f], f.file_id == ^id)
      |> join_assoc_modules()
      |> preload_modules()
    end

    @spec by_storage(Queryable.t, Storage.idtb) ::
      Queryable.t
    def by_storage(query \\ File, id),
      do: where(query, [f], f.storage_id == ^id)

    def by_version(query \\ File, storage, module) do
      File
      |> where([f], f.storage_id == ^storage)
      |> join(:left, [f], fm in FileModule, f.file_id == fm.file_id)
      |> where([..., fm], fm.name == ^module)
      |> order_by([..., fm], desc: fm.version)
      |> select([fm], fm.file_id)
      |> limit(1)
    end

    def by_module(query, module_name),
      do: where(query, [..., fm], fm.name == ^module_name)

    def order_by_version(query),
      do: order_by(query, [..., fm], desc: fm.version)

    @spec not_encrypted(Queryable.t) ::
      Queryable.t
    def not_encrypted(query \\ File),
      do: where(query, [f], is_nil(f.crypto_version))

    defp join_modules(query),
      do: join(query, :left, [f], fm in FileModule, fm.file_id == f.file_id)

    defp join_assoc_modules(query),
      do: join(query, :left, [f], fm in assoc(f, :modules))

    docp """
    Preloads FileModules into the schema
    """
    defp preload_modules(query),
      do: preload(query, [..., m], [modules: m])
  end
end
