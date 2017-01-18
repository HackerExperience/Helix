defmodule Helix.Entity.Model.EntityType do

  use Ecto.Schema

  import Ecto.Changeset

  @type name :: String.t
  @type t :: %__MODULE__{
    entity_type: name
  }

  @creation_fields ~w/entity_type/a

  @primary_key false
  schema "entity_types" do
    field :entity_type, :string,
      primary_key: true
  end

  @spec create_changeset(%{entity_type: name}) :: Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(:entity_type)
    |> unique_constraint(:entity_type)
  end
end