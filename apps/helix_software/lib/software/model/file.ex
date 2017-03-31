defmodule Helix.Software.Model.File do

  use Ecto.Schema

  alias HELL.PK
  alias Helix.Software.Model.SoftwareType
  alias Helix.Software.Model.File
  alias Helix.Software.Model.FileModule
  alias Helix.Software.Model.Storage

  import Ecto.Changeset

  @type t :: %__MODULE__{
    file_id: PK.t,
    name: String.t,
    path: String.t,
    full_path: String.t,
    file_size: pos_integer,
    type: SoftwareType.t,
    software_type: String.t,
    storage: Storage.t,
    storage_id: PK.t,
    inserted_at: NaiveDateTime.t,
    updated_at: NaiveDateTime.t
  }

  @type id :: PK.t

  @type modules :: %{software_module :: String.t => version :: pos_integer}

  @type creation_params :: %{
    name: String.t,
    path: String.t,
    file_size: pos_integer,
    software_type: String.t,
    storage_id: PK.t
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

  @primary_key false
  @ecto_autogenerate {:file_id, {PK, :pk_for, [__MODULE__]}}
  schema "files" do
    field :file_id, HELL.PK,
      primary_key: true

    field :name, :string
    field :path, :string
    field :software_type, :string
    field :file_size, :integer
    field :storage_id, HELL.PK

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

  @spec create(Storage.t, map) :: Ecto.Changeset.t
  def create(storage = %Storage{}, params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> put_assoc(:storage, storage)
    |> changeset(params)
  end

  @spec create_changeset(creation_params) :: Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> cast(params, [:storage_id])
    |> validate_required([:storage_id])
    |> changeset(params)
  end

  @spec update_changeset(t | Ecto.Changeset.t, update_params) :: Ecto.Changeset.t
  def update_changeset(struct, params) do
    struct
    |> cast(params, @update_fields)
    |> changeset(params)
    |> validate_number(:crypto_version, greater_than: 0)
  end

  @spec set_modules(File.t, modules) :: Ecto.Changeset.t
  def set_modules(file, modules) do
    modules =
      Enum.map(modules, fn {module, version} ->
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
    |> unique_constraint(:full_path, name: :files_storage_id_full_path_index)
    |> update_change(:path, &add_leading_slash/1)
    |> update_change(:path, &remove_leading_slash/1)
    |> prepare_changes(&update_full_path/1)
  end

  defp update_full_path(changeset) do
    path = get_field(changeset, :path)
    name = get_field(changeset, :name)
    software_type = get_field(changeset, :software_type)
    extension = SoftwareType.possible_types[software_type].extension

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

    alias Ecto.Queryable
    alias Helix.Software.Model.File
    alias Helix.Software.Model.Storage

    import Ecto.Query, only: [or_where: 3, where: 3]

    @spec from_id_list(Queryable.t, [HELL.PK.t]) :: Queryable.t
    def from_id_list(query \\ File, id_list, comparison_operator \\ :and)
    def from_id_list(query, id_list, :and),
      do: where(query, [f], f.file_id in ^id_list)
    def from_id_list(query, id_list, :or),
      do: or_where(query, [f], f.file_id in ^id_list)

    @spec from_storage(Queryable.t, Storage.t) :: Queryable.t
    def from_storage(query \\ File, %Storage{storage_id: id}),
      do: where(query, [f], f.storage_id == ^id)

    @spec not_encrypted(Queryable.t) :: Queryable.t
    def not_encrypted(query \\ File),
      do: where(query, [f], is_nil(f.crypto_version))
  end
end
