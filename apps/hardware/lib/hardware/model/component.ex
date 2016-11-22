defmodule HELM.Hardware.Model.Component do

  use Ecto.Schema

  alias HELL.PK
  alias HELM.Hardware.Model.MotherboardSlot, as: MdlMoboSlot, warn: false
  alias HELM.Hardware.Model.ComponentSpec, as: MdlCompSpec, warn: false
  import Ecto.Changeset

  @type t :: %__MODULE__{
    component_id: PK.t,
    component_type: String.t,
    component_spec: MdlCompSpec.t,
    spec_id: PK.t,
    slot: MdlMoboSlot.t,
    inserted_at: Ecto.DateTime.t,
    updated_at: Ecto.DateTime.t
  }

  @type creation_params :: %{component_type: String.t, spec_id: PK.t}
  @type update_params :: %{spec_id: PK.t}

  @creation_fields ~w/component_type spec_id/a
  @update_fields ~w/spec_id/a

  @primary_key false
  schema "components" do
    field :component_id, EctoNetwork.INET,
      primary_key: true

    field :component_type, :string

    belongs_to :component_spec, MdlCompSpec,
      foreign_key: :spec_id,
      references: :spec_id,
      type: EctoNetwork.INET
    has_one :slot, MdlMoboSlot,
      foreign_key: :link_component_id,
      references: :component_id

    timestamps
  end

  @spec create_changeset(creation_params) :: Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required([:component_type, :spec_id])
    |> put_primary_key()
  end

  @spec update_changeset(t | Ecto.Changeset.t, update_params) :: Ecto.Changeset.t
  def update_changeset(schema, params) do
    schema
    |> cast(params, @update_fields)
  end

  @spec put_primary_key(Ecto.Changeset.t) :: Ecto.Changeset.t
  defp put_primary_key(changeset) do
    ip = PK.generate([0x0003, 0x0001, 0x0000])

    changeset
    |> cast(%{component_id: ip}, [:component_id])
  end
end