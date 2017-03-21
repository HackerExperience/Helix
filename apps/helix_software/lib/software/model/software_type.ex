defmodule Helix.Software.Model.SoftwareType do

  use Ecto.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{
    software_type: String.t,
    extension: String.t
  }

  @creation_fields ~w/software_type extension/a

  @primary_key false
  schema "software_types" do
    field :software_type, :string,
      primary_key: true

    field :extension, :string
  end

  @spec create_changeset(%{software_type: String.t, extension: String.t}) :: Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(@creation_fields)
    |> unique_constraint(:software_type)
  end
end