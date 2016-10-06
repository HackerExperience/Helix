defmodule HELM.Hardware.Component.Type.Schema do
  use Ecto.Schema

  import Ecto.Changeset
  alias HELM.Hardware.Component

  @primary_key {:component_type, :string, autogenerate: false}
  @creation_fields ~w(component_type)

  schema "component_types" do
    timestamps
  end

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(:component_type)
  end
end
