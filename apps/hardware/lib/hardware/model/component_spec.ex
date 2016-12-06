defmodule HELM.Hardware.Model.ComponentSpec do

  use Ecto.Schema

  alias HELL.PK
  alias HELM.Hardware.Model.Component, as: MdlComp, warn: false
  import Ecto.Changeset

  @type t :: %__MODULE__{
    spec_id: PK.t,
    component_type: String.t,
    spec: %{},
    inserted_at: Ecto.DateTime.t,
    updated_at: Ecto.DateTime.t
  }

  @type creation_params :: %{
    component_type: String.t,
    spec: %{}}
  @type update_params :: %{spec: %{}}

  @creation_fields ~w/spec component_type/a
  @update_fields ~w/spec/a

  @primary_key false
  schema "component_specs" do
    field :spec_id, EctoNetwork.INET,
      primary_key: true

    field :component_type, :string
    field :spec, :map

    has_many :components, MdlComp,
      foreign_key: :spec_id,
      references: :spec_id

    timestamps
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
    |> validate_required(:spec)
  end

  @spec put_primary_key(Ecto.Changeset.t) :: Ecto.Changeset.t
  defp put_primary_key(changeset) do
    ip = PK.generate([0x0003, 0x0000, 0x0000])

    changeset
    |> cast(%{spec_id: ip}, [:spec_id])
  end
end