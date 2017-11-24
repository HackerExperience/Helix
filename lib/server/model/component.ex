defmodule Helix.Server.Model.Component do

  use Ecto.Schema
  use HELL.ID, field: :component_id, meta: [0x0012]

  import Ecto.Changeset
  import HELL.Ecto.Macros

  alias Ecto.Changeset
  alias HELL.Constant
  alias Helix.Server.Componentable
  alias Helix.Server.Component.Specable
  alias __MODULE__, as: Component

  @type t :: t_of_type(type)
  @typep t_of_type(custom_type) ::
    %__MODULE__{
      component_id: id,
      type: custom_type,
      custom: custom,
      spec_id: Component.Spec.id
    }

  @type changeset :: %Changeset{data: %__MODULE__{}}

  @type cpu :: t_of_type(:cpu)
  @type hdd :: t_of_type(:hdd)
  @type ram :: t_of_type(:ram)
  @type nic :: t_of_type(:nic)
  @type mobo :: t_of_type(:mobo)

  @type pluggable :: cpu | hdd | ram | nic

  @type type :: :cpu | :hdd | :ram | :nic | :mobo

  @type custom ::
    Component.CPU.custom
    | Component.RAM.custom
    | Component.HDD.custom
    | Component.NIC.custom
    | Component.Mobo.custom

  @creation_fields [:type, :spec_id, :custom]
  @required_fields [:type, :spec_id, :custom]

  @primary_key false
  schema "components" do
    field :component_id, ID,
      primary_key: true

    field :type, Constant

    field :custom, :map

    field :spec_id, Constant
  end

  @spec format(Component.t) ::
    Component.t
  @doc """
  Recovers internal Elixir/Erlang/Helix format.
  """
  def format(component = %Component{}) do
    %{component|
      custom: Specable.format_custom(component)
    }
  end

  @spec create_from_spec(Component.Spec.t) ::
    changeset
  def create_from_spec(spec = %Component.Spec{}) do
    params =
      %{
        type: spec.component_type,
        spec_id: spec.spec_id,
        custom: Component.Spec.create_custom(spec)
      }

    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(@required_fields)
  end

  defdelegate get_types,
    to: Componentable

  defdelegate get_resources(component),
    to: Componentable

  @spec update_custom(Component.t, map) ::
    changeset
  def update_custom(component = %Component{}, changes) do
    new_custom = Componentable.update_custom(component, changes)

    component
    |> change()
    |> put_change(:custom, new_custom)
  end

  query do

    def by_id(query \\ Component, component_id),
      do: where(query, [c], c.component_id == ^component_id)
  end
end
