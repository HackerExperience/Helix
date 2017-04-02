defmodule Helix.Software.Model.SoftwareModule do

  use Ecto.Schema

  alias HELL.Constant
  alias Helix.Software.Model.SoftwareType

  @type t :: %__MODULE__{
    software_module: Constant.t,
    software_type: String.t
  }

  @software_modules Enum.flat_map(
    SoftwareType.possible_types(),
    fn {_, %{modules: m}} -> m end)

  @primary_key false
  schema "software_modules" do
    field :software_module, Constant,
      primary_key: true

    # FK to SoftwareType
    field :software_type, Constant
  end

  @doc false
  def possible_modules do
    @software_modules
  end

  defmodule Query do

    alias HELL.Constant
    alias Helix.Software.Model.SoftwareModule

    import Ecto.Query, only: [where: 3]

    @spec by_software_type(Ecto.Queryable.t, Constant.t) :: Ecto.Queryable.t
    def by_software_type(query \\ SoftwareModule, software_type),
      do: where(query, [m], m.software_type == ^software_type)
  end
end
