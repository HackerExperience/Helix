defmodule Helix.Hardware.Model.ComponentType do

  use Ecto.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{
    component_type: String.t
  }

  @creation_fields ~w/component_type/a

  @primary_key false
  schema "component_types" do
    field :component_type, :string,
      primary_key: true
  end

  @spec create_changeset(%{component_type: String.t}) :: Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(:component_type)
    |> unique_constraint(:component_type)
  end
end