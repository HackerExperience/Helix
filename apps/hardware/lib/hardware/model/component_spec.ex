defmodule Helix.Hardware.Model.ComponentSpec do

  use Ecto.Schema

  alias Helix.Hardware.Model.Component, as: MdlComp, warn: false
  import Ecto.Changeset

  @type t :: %__MODULE__{
    spec_code: String.t,
    component_type: String.t,
    spec: %{},
    inserted_at: NaiveDateTime.t,
    updated_at: NaiveDateTime.t
  }

  @type creation_params :: %{
    component_type: String.t,
    spec: %{}}
  @type update_params :: %{spec: %{}}

  @creation_fields ~w/spec component_type/a
  @update_fields ~w/spec/a

  @primary_key false
  schema "component_specs" do
    field :spec_code, :string,
      primary_key: true

    field :component_type, :string
    field :spec, :map

    timestamps()
  end

  @spec create_changeset(creation_params) :: Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required([:component_type, :spec])
    |> put_primary_key()
  end

  @spec update_changeset(t | Ecto.Changeset.t, update_params) :: Ecto.Changeset.t
  def update_changeset(schema, params) do
    schema
    |> cast(params, @update_fields)
    |> validate_required([:spec, :spec_code])
  end

  @spec put_primary_key(Ecto.Changeset.t) :: Ecto.Changeset.t
  defp put_primary_key(changeset) do
    spec_code =
      changeset
      |> get_field(:spec)
      |> Map.fetch!(:spec_code)

    changeset
    |> cast(%{spec_code: spec_code}, [:spec_code])
  end
end