defmodule HELM.Hardware.Model.ComponentSpec do
  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset

  alias HELM.Hardware.Model.Component, as: MdlComp

  @primary_key {:spec_id, :string, autogenerate: false}
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
    |> put_id
  end

  defp put_id(changeset) do
    if changeset.valid?,
      do: Changeset.put_change(changeset, :spec_id, HELL.ID.generate("CSPC")),
      else: changeset
  end
end