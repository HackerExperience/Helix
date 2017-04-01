defmodule Helix.Software.Model.SoftwareModule do

  use Ecto.Schema

  @type t :: %__MODULE__{
    software_module: String.t,
    software_type: String.t
  }

  @primary_key false
  schema "software_modules" do
    field :software_module, :string,
      primary_key: true

    # FK to SoftwareType
    field :software_type, :string
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
