defmodule Helix.Software.Model.TextFile do

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias Helix.Software.Model.File
  alias Helix.Software.Model.Storage

  @type t :: %__MODULE__{
    file_id: File.id,
    contents: String.t,
    file: term
  }

  @software_type :text

  @primary_key false
  schema "text_files" do
    field :file_id, File.ID,
      primary_key: true

    field :contents, :string

    belongs_to :file, File,
      foreign_key: :file_id,
      references: :file_id,
      define_field: false
  end

  @spec create(Storage.t, String.t, String.t, String.t) ::
    Changeset.t
  @doc """
  Creates a `text file`  on `storage`.
  """
  def create(storage = %Storage{}, name, path, contents) do
    file = generate_file(storage, name, path)

    %__MODULE__{}
    |> changeset(%{contents: contents})
    |> put_assoc(:file, file)
  end

  @spec update_contents(t | Changeset.t, String.t) ::
    Changeset.t
  @doc """
  Updates `text file`  contents.
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
    # REVIEW: text files should have a size? If so, we need to check if the
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
    import Ecto.Query

    alias Ecto.Queryable
    alias Helix.Software.Model.File
    alias Helix.Software.Model.TextFile

    @spec by_file(Queryable.t, File.idtb) ::
      Queryable.t
    def by_file(query \\ TextFile, id),
      do: where(query, [ft], ft.file_id == ^id)
  end
end
