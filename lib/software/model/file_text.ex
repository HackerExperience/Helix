defmodule Helix.Software.Model.FileText do

  use Ecto.Schema

  alias HELL.PK
  alias Helix.Software.Model.File
  alias Helix.Software.Model.Storage

  import Ecto.Changeset

  @type t :: %__MODULE__{
    file: File.t,
    file_id: PK.t,
    contents: String.t
  }

  @type creation_params :: %{
    name: String.t,
    path: String.t,
    contents: String.t
  }

  @software_type :text

  @primary_key false
  schema "file_texts" do
    field :file_id, PK,
      primary_key: true

    field :contents, :string

    belongs_to :file, File,
      foreign_key: :file_id,
      references: :file_id,
      type: PK,
      define_field: false
  end

  @spec create(Storage.t, String.t, String.t, String.t) ::
    Ecto.Changeset.t
  @doc """
  Creates a `file text`  on `storage`.
  """
  def create(storage = %Storage{}, name, path, contents) do
    file = generate_file(storage, name, path)

    %__MODULE__{}
    |> changeset(%{contents: contents})
    |> put_assoc(:file, file)
  end

  @spec update_contents(t | Ecto.Changeset.t, String.t) ::
    Ecto.Changeset.t
  @doc """
  Updates `file text`  contents.
  """
  def update_contents(struct, contents),
    do: changeset(struct, %{contents: contents})

  def changeset(struct, params) do
    # REVIEW: if needed, update file_size according to contents size
    struct
    |> cast(params, [:contents])
    |> validate_length(:contents, max: 8192)
  end

  defp generate_file(storage, name, path) do
    # REVIEW: Text files should have a size? If so, we need to check if the
    # storage can store them
    params = %{
      name: name,
      path: path,
      file_size: 1,
      software_type: @software_type
    }

    File.create(storage, params)
  end

  defmodule Query do

    alias Helix.Software.Model.File
    alias Helix.Software.Model.FileText

    import Ecto.Query, only: [where: 3]

    @spec from_file(Ecto.Queryable.t, File.t | File.id) ::
      Ecto.Queryable.t
    def from_file(query \\ FileText, file_or_file_id)
    def from_file(query, file = %File{}),
      do: from_file(query, file.file_id)
    def from_file(query, file_id),
      do: where(query, [ft], ft.file_id == ^file_id)
  end
end
