defmodule Helix.Hardware.Model.Component do

  use Ecto.Schema

  alias HELL.PK
  alias Helix.Hardware.Model.MotherboardSlot, as: MdlMoboSlot, warn: false
  alias Helix.Hardware.Model.ComponentSpec, as: MdlCompSpec, warn: false
  import Ecto.Changeset

  @type t :: %__MODULE__{
    component_id: PK.t,
    component_type: String.t,
    component_spec: MdlCompSpec.t,
    spec_id: Strint.t,
    slot: MdlMoboSlot.t,
    inserted_at: NaiveDateTime.t,
    updated_at: NaiveDateTime.t
  }

  @type creation_params :: %{component_type: String.t, spec_id: String.t}

  @creation_fields ~w/component_type spec_id/a

  @primary_key false
  schema "components" do
    field :component_id, HELL.PK,
      primary_key: true

    field :component_type, :string

    belongs_to :component_spec, MdlCompSpec,
      foreign_key: :spec_id,
      references: :spec_id,
      type: :string
    has_one :slot, MdlMoboSlot,
      foreign_key: :link_component_id,
      references: :component_id

    timestamps()
  end

  @spec create_changeset(creation_params) :: Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required([:component_type, :spec_id])
    |> put_primary_key()
  end

  @spec put_primary_key(Ecto.Changeset.t) :: Ecto.Changeset.t
  defp put_primary_key(changeset) do
    ip = PK.generate([0x0003, 0x0001, 0x0000])

    changeset
    |> cast(%{component_id: ip}, [:component_id])
  end
end