defmodule Helix.Software.Model.File do

  use Ecto.Schema
  use HELL.ID, field: :file_id, meta: [0x0020]

  import Ecto.Changeset
  import HELL.Macros

  alias Ecto.Changeset
  alias HELL.Constant
  alias Helix.Software.Model.Software
  alias Helix.Software.Model.Storage
  alias __MODULE__, as: File

  @type t :: t_of_type(Software.type)

  @type t_of_type(type) :: %__MODULE__{
    file_id: id,
    name: name,
    path: path,
    full_path: full_path,
    file_size: size,
    type: Software.Type.t,
    software_type: type,
    storage_id: Storage.id,
    storage: term,
    inserted_at: NaiveDateTime.t,
    updated_at: NaiveDateTime.t,
    modules: modules | File.Module.schema,
    crypto_version: crypto_version
  }

  @type extension :: String.t
  @type path :: String.t
  @type full_path :: path
  @type name :: String.t
  @type size :: pos_integer
  @type type :: Software.type
  @type crypto_version :: nil | pos_integer
  @type modules :: File.Module.t

  @type changeset :: %Changeset{data: %__MODULE__{}}

  @type creation_params :: %{
    name: name,
    path: path,
    file_size: size,
    software_type: Software.type,
    storage_id: Storage.idtb
  }

  @type module_params :: {File.Module.name, File.Module.Data.t}

  @type update_params :: %{
    optional(:name) => name,
    optional(:path) => path,
    optional(:crypto_version) => non_neg_integer | nil
  }

  @creation_fields ~w/name path storage_id file_size software_type/a
  @update_fields ~w/crypto_version/a
  @castable_fields ~w/name path/a

  @required_fields ~w/name path file_size software_type storage_id/a

  @software_types Software.Type.all()

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

    belongs_to :type, Software.Type,
      foreign_key: :software_type,
      references: :type,
      define_field: false
    belongs_to :storage, Storage,
      foreign_key: :storage_id,
      references: :storage_id,
      define_field: false

    has_many :modules, File.Module,
      foreign_key: :file_id,
      references: :file_id,
      on_replace: :delete

    timestamps()
  end

  @spec create_changeset(creation_params, [module_params]) ::
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

  @spec format(t) ::
    t
  @doc """
  Formats the given `File`. Most notably, this function makes the File.Modules
  interface more friendly.
  """
  def format(file) do
    formatted_modules =
      Enum.reduce(file.modules, %{}, fn module, acc ->
        module = File.Module.format(module)
        Map.merge(acc, module)
      end)

    file
    |> Map.replace(:modules, formatted_modules)
    # For some reason, Ecto assigns the `:built` state sometimes, which leads to
    # some weird behaviour on some Repo inserts. As suggested here[1], we'll use
    # Ecto.put_meta/2. [1] - https://github.com/Nebo15/ecto_mnesia/issues/20
    |> Ecto.put_meta(state: :loaded)
  end

  @spec set_crypto_version(t | changeset, crypto_version) ::
    changeset
  def set_crypto_version(struct, version) do
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

  @spec create_module_assoc(module_params) ::
    File.Module.changeset
  docp """
  Helper/wrapper to `File.Module.create_changeset/1`
  """
  defp create_module_assoc({name, data}) do
    params = %{
      name: name,
      version: data.version
    }

    File.Module.create_changeset(params)
  end

  docp """
  Path: Path from root dir (`/`) to file directory
  Full path: `path` + `File.name` + `File.extension`
  """
  defp update_full_path(changeset) do
    path = get_field(changeset, :path)
    name = get_field(changeset, :name)
    software_type = get_field(changeset, :software_type)
    extension = Software.Type.get(software_type).extension

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
    @doc """
    Query by file id.
    """
    def by_file(query \\ File, id) do
      query
      |> where([f], f.file_id == ^id)
      |> join_assoc_modules()
      |> preload_modules()
    end

    @spec by_storage(Queryable.t, Storage.idtb) ::
      Queryable.t
    @doc """
    Query by storage id.
    """
    def by_storage(query \\ File, id),
      do: where(query, [f], f.storage_id == ^id)

    @spec by_version(Queryable.t, Storage.idtb, File.Module.name) ::
      Queryable.t
    @doc """
    Query by (highest) File.Module.name version.
    """
    def by_version(query \\ File, storage, module) do
      query
      |> by_storage(storage)
      |> join_modules()
      |> by_module(module)
      |> order_by_version()
      |> select([fm], fm.file_id)
      |> limit(1)
    end

    @spec by_module(Queryable.t, File.Module.name) ::
      Queryable.t
    @doc """
    Query by File.Module.name
    """
    def by_module(query, module_name),
      do: where(query, [..., fm], fm.name == ^module_name)

    @spec order_by_version(Queryable.t) ::
      Queryable.t
    @doc """
    Order by File.Module version, descending.
    """
    def order_by_version(query),
      do: order_by(query, [..., fm], desc: fm.version)

    @spec not_encrypted(Queryable.t) ::
      Queryable.t
    @doc """
    Filter out encrypted files.
    """
    def not_encrypted(query \\ File),
      do: where(query, [f], is_nil(f.crypto_version))

    @spec join_modules(Queryable.t) ::
      Queryable.t
    docp """
    Join File.Module.
    """
    defp join_modules(query),
      do: join(query, :left, [f], fm in File.Module, fm.file_id == f.file_id)

    @spec join_assoc_modules(Queryable.t) ::
      Queryable.t
    docp """
    Join File.Module through Ecto Schema's association.
    """
    defp join_assoc_modules(query),
      do: join(query, :left, [f], fm in assoc(f, :modules))

    @spec preload_modules(Queryable.t) ::
      Queryable.t
    docp """
    Preloads File.Modules into the schema
    """
    defp preload_modules(query),
      do: preload(query, [..., m], [modules: m])
  end
end
