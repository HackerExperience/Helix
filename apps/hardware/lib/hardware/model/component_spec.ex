defmodule HELM.Hardware.Model.ComponentSpec do

  use Ecto.Schema

  alias HELM.Hardware.Model.Component, as: MdlComp, warn: false
  import Ecto.Changeset

  @type t :: %__MODULE__{
    spec_id: String.t,
    component_type: String.t,
    spec: %{},
    inserted_at: Ecto.DateTime.t,
    updated_at: Ecto.DateTime.t
  }

  @type creation_params :: %{
    spec_id: String.t,
    component_type: String.t,
    spec: %{}}
  @type update_params :: %{spec: %{}}

  @creation_fields ~w/spec component_type spec_id/a
  @update_fields ~w/spec/a

  @primary_key false
  schema "component_specs" do
    field :spec_id, :string,
      primary_key: true

    field :component_type, :string
    field :spec, :map

    timestamps
  end

  @spec create_changeset(creation_params) :: Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required([:spec_id, :component_type, :spec])
  end

  @spec update_changeset(t | Ecto.Changeset.t, update_params) :: Ecto.Changeset.t
  def update_changeset(schema, params) do
    schema
    |> cast(params, @update_fields)
    |> validate_required(:spec)
  end
end