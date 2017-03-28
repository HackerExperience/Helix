defmodule Helix.Software.Model.SoftwareModule do

  use Ecto.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{
    software_module: String.t,
    software_type: String.t
  }

  @type creation_params :: %{software_type: String.t, software_module: String.t}

  @creation_fields ~w/software_type software_module/a

  @primary_key false
  schema "software_modules" do
    field :software_module, :string,
      primary_key: true

    # FK to SoftwareType
    field :software_type, :string
  end

  @spec create_changeset(creation_params) :: Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required([:software_module, :software_type])
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
