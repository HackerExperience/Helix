defmodule Helix.Software.Model.File do

  use Ecto.Schema
  use HELL.ID, field: :file_id, meta: [0x0020]

  import Ecto.Changeset

  alias Ecto.Changeset
  alias HELL.Constant
  alias Helix.Software.Model.SoftwareType
  alias Helix.Software.Model.FileModule
  alias Helix.Software.Model.Storage

  @type module_name :: Constant.t
  @type modules :: %{optional(module_name) => pos_integer}
  @type t :: %__MODULE__{
    file_id: id,
    name: String.t,
    path: String.t,
    full_path: String.t,
    file_size: pos_integer,
    type: SoftwareType.t,
    software_type: Constant.t,
    storage_id: Storage.id,
    storage: term,
    inserted_at: NaiveDateTime.t,
    updated_at: NaiveDateTime.t
  }

  @type creation_params :: %{
    name: String.t,
    path: String.t,
    file_size: pos_integer,
    software_type: Constant.t,
    storage_id: Storage.idtb
  }

  @type update_params :: %{
    optional(:name) => String.t,
    optional(:path) => String.t,
    optional(:crypto_version) => non_neg_integer | nil
  }

  @creation_fields ~w/file_size software_type/a
  @update_fields ~w/crypto_version/a
  @castable_fields ~w/name path/a

  @required_fields ~w/name path file_size software_type/a

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

    has_many :file_modules, FileModule,
      foreign_key: :file_id,
      references: :file_id

    timestamps()
  end

  @spec create(Storage.t, map) ::
    Changeset.t
  def create(storage = %Storage{}, params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> put_assoc(:storage, storage)
    |> changeset(params)
  end

  @spec copy(t, Storage.t, map) ::
    Changeset.t
  def copy(file, storage, params) do
    # dropping :file_id to avoid Ecto thinking this is an update
    base =
      file
      |> Map.take(__schema__(:fields))
      |> Map.drop([:file_id, :storage_id, :full_path])

    __MODULE__
    |> struct(base)
    |> changeset(params)
    |> put_assoc(:storage, storage)
  end

  @spec create_changeset(creation_params) ::
    Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> cast(params, [:storage_id])
    |> validate_required([:storage_id])
    |> changeset(params)
  end

  @spec update_changeset(t | Changeset.t, update_params) ::
    Changeset.t
  def update_changeset(struct, params) do
    struct
    |> cast(params, @update_fields)
    |> changeset(params)
    |> validate_number(:crypto_version, greater_than: 0)
  end

  @spec set_modules(t, modules) ::
    Changeset.t
  def set_modules(file, modules) do
    modules = Enum.map(modules, fn {module, version} ->
      %{software_module: module, module_version: version}
    end)

    file
    |> cast(%{file_modules: modules}, [])
    |> cast_assoc(:file_modules)
  end

  defp changeset(struct, params) do
    struct
    |> cast(params, @castable_fields)
    |> validate_required(@required_fields)
    |> validate_number(:file_size, greater_than: 0)
    |> validate_inclusion(:software_type, @software_types)
    |> unique_constraint(:full_path, name: :files_storage_id_full_path_index)
    |> update_change(:path, &add_leading_slash/1)
    |> update_change(:path, &remove_leading_slash/1)
    |> prepare_changes(&update_full_path/1)
  end

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

  # Removes the leading slash of a string if any unless it is the only char
  defp remove_leading_slash(path) do
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

    alias Ecto.Queryable
    alias Helix.Software.Model.File
    alias Helix.Software.Model.Storage

    @spec from_id_list(Queryable.t, [File.id]) ::
      Queryable.t
    def from_id_list(query \\ File, id_list, comparison_operator \\ :and)
    def from_id_list(query, id_list, :and),
      do: where(query, [f], f.file_id in ^id_list)
    def from_id_list(query, id_list, :or),
      do: or_where(query, [f], f.file_id in ^id_list)

    @spec by_storage(Queryable.t, Storage.idtb) ::
      Queryable.t
    def by_storage(query \\ File, id),
      do: where(query, [f], f.storage_id == ^id)

    @spec not_encrypted(Queryable.t) ::
      Queryable.t
    def not_encrypted(query \\ File),
      do: where(query, [f], is_nil(f.crypto_version))
  end
end
