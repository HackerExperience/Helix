defmodule HELM.Hardware.Model.ComponentSpec do
  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset

  alias HELL.IPv6
  alias HELM.Hardware.Model.Component, as: MdlComp, warn: false

  @primary_key {:spec_id, EctoNetwork.INET, autogenerate: false}
  @creation_fields ~w/spec component_type/a

  schema "component_specs" do
    field :component_type, :string
    field :spec, :map

    has_many :components, MdlComp,
      foreign_key: :spec_id,
      references: :spec_id

    timestamps
  end

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(:spec)
    |> put_primary_key()
  end

  defp put_primary_key(changeset) do
    ip = IPv6.generate([0x0003, 0x0000, 0x0000])

    changeset
    |> cast(%{spec_id: ip}, ~w(spec_id))
  end
end