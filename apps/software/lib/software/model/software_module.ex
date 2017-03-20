defmodule Helix.Software.Model.SoftwareModule do

  use Ecto.Schema

  alias HELL.PK
  alias Helix.Software.Model.FileType

  import Ecto.Changeset

  @type t :: %__MODULE__{
    software_module_id: PK.t,
    software_module: String.t,
    type: FileType.t
  }

  @creation_fields ~w/file_type software_module/a

  @primary_key false
  schema "software_modules" do
    field :software_module, :string,
      primary_key: true

    # FIXME: this name must change soon
    belongs_to :type, FileType,
      foreign_key: :file_type,
      references: :file_type,
      type: :string
  end

  @spec create_changeset(%{file_type: String.t, software_module: String.t}) :: Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required([:software_module, :file_type])
    |> unique_constraint(:software_module, name: :file_type_software_module_unique_constraint)
  end

  defmodule Query do

    alias Helix.Software.Model.SoftwareModule

    import Ecto.Query, only: [where: 3]

    @spec by_file_type(String.t) :: Ecto.Queryable.t
    @spec by_file_type(Ecto.Queryable.t, String.t) :: Ecto.Queryable.t
    def by_file_type(query \\ SoftwareModule, file_type),
      do: where(query, [m], m.file_type == ^file_type)
  end
end