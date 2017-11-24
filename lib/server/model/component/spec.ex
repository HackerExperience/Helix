defmodule Helix.Server.Model.Component.Spec do

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias HELL.Constant
  alias Helix.Server.Component.Specable
  alias Helix.Server.Model.Component

  @type id ::
    Specable.CPU.id
    | Specable.RAM.id
    | Specable.HDD.id
    | Specable.NIC.id
    | Specable.MOBO.id

  @type cpu :: Specable.CPU.id
  @type ram :: Specable.RAM.id
  @type hdd :: Specable.HDD.id
  @type nic :: Specable.NIC.id
  @type mobo :: Specable.MOBO.id

  @type t ::
    %__MODULE__{
      spec_id: id,
      component_type: Component.type,
      data: data
    }

  @type changeset :: %Changeset{data: %__MODULE__{}}

  @type data :: spec
  @type spec ::
    Specable.CPU.spec
    | Specable.RAM.spec
    | Specable.HDD.spec
    | Specable.NIC.spec
    | Specable.MOBO.spec

  @creation_fields [:spec_id, :component_type, :data]

  @primary_key false
  schema "component_specs" do

    field :spec_id, Constant,
      primary_key: true

    field :component_type, Constant

    field :data, :map
  end

  @spec create_changeset(id, Component.type, spec) ::
    changeset
  def create_changeset(spec_id, component_type, spec) do
    params =
      %{
        spec_id: spec_id,
        component_type: component_type,
        data: spec
      }

    %__MODULE__{}
    |> cast(params, @creation_fields)
  end

  @spec fetch(id) ::
    t
    | nil
  def fetch(spec_id) do
    spec = Specable.fetch(spec_id)

    if spec do
      %__MODULE__{
        spec_id: spec.spec_id,
        component_type: spec.component_type,
        data: spec
      }
    end
  end

  @spec get_initial(Component.type) ::
    t
  def get_initial(component_type) do
    component_type
    |> Specable.get_initial()
    |> fetch()
  end

  defdelegate create_custom(spec),
    to: Specable
end
