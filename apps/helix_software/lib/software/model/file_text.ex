defmodule Helix.Software.Model.FileText do

  use Ecto.Schema

  alias HELL.PK
  alias Helix.Software.Model.File

  import Ecto.Changeset

  @type t :: %__MODULE__{
    file_id: PK.t,
    contents: String.t
  }

  @type creation_params :: %{
    file_id: PK.t,
    contents: String.t
  }

  @type update_params :: %{
    contents: String.t
  }

  @creation_fields ~w/file_id contents/a
  @update_fields ~w/contents/a

  @primary_key false
  schema "file_texts" do
    belongs_to :file, File,
      foreign_key: :file_id,
      references: :file_id,
      type: PK,
      primary_key: true

    field :contents, :string, default: ""
  end

  @spec create_changeset(%{file_id: PK.t, contents: String.t}) ::
    Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required([:file_id, :contents])
    |> generic_validations()
  end

  @spec update_changeset(t | Ecto.Changeset.t, %{contents: String.t}) ::
    Ecto.Changeset.t
  def update_changeset(schema_or_changeset, params) do
    schema_or_changeset
    |> cast(params, @update_fields)
    |> validate_required(:contents)
    |> generic_validations()
  end

  @spec generic_validations(Ecto.Changeset.t) :: Ecto.Changeset.t
  def generic_validations(changeset),
    do: validate_length(changeset, :contents, max: 8192)

  defmodule Query do

    alias Helix.Software.Model.File
    alias Helix.Software.Model.FileText

    import Ecto.Query, only: [where: 3]

    @spec from_file(File.t | File.id) :: Ecto.Queryable.t
    @spec from_file(Ecto.Queryable.t, File.t | File.id) :: Ecto.Queryable.t
    def from_file(query \\ FileText, file_or_file_id)

    def from_file(query, file = %File{}),
      do: from_file(query, file.file_id)
    def from_file(query, file_id),
      do: where(query, [ft], ft.file_id == ^file_id)
  end
end