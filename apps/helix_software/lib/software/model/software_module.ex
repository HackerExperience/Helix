defmodule Helix.Software.Model.SoftwareModule do

  use Ecto.Schema

  alias Helix.Software.Model.SoftwareType

  import Ecto.Changeset

  @type t :: %__MODULE__{
    software_module: String.t,
    type: SoftwareType.t
  }

  @creation_fields ~w/software_type software_module/a

  @primary_key false
  schema "software_modules" do
    field :software_module, :string, primary_key: true

    # FIXME: this name must change soon
    belongs_to :type, SoftwareType,
      foreign_key: :software_type,
      references: :software_type,
      type: :string
  end

  @spec create_changeset(%{software_type: String.t, software_module: String.t}) :: Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required([:software_module, :software_type])
    |> unique_constraint(:software_module, name: :software_modules_software_type_software_module_index)
  end

  defmodule Query do

    alias Helix.Software.Model.SoftwareModule

    import Ecto.Query, only: [where: 3]

    @spec by_software_type(String.t) :: Ecto.Queryable.t
    @spec by_software_type(Ecto.Queryable.t, String.t) :: Ecto.Queryable.t
    def by_software_type(query \\ SoftwareModule, software_type),
      do: where(query, [m], m.software_type == ^software_type)
  end
end
