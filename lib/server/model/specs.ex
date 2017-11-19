defmodule Helix.Server.Model.Component.Spec do

  use Ecto.Schema

  import Ecto.Changeset

  alias HELL.Constant
  alias Helix.Server.Component.Specable

  @type id :: term

  @type t ::
    %__MODULE__{
      spec_id: id,
      component_type: component_type,
      data: data
    }

  @type data :: spec
  @type spec ::
    %{
      :spec_id => String.t,
      :spec_type => String.t,
      :name => String.t,
      optional(atom) => any
    }

  @typep component_type :: Constant.t

  @creation_fields [:spec_id, :component_type, :data]

  @primary_key false
  schema "component_specs" do

    field :spec_id, Constant,
      primary_key: true

    field :component_type, Constant

    field :data, :map
  end

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

  def fetch(spec_id) do
    spec = Specable.fetch(spec_id)

    %__MODULE__{
      spec_id: spec.spec_id,
      component_type: spec.component_type,
      data: spec
    }
  end

  defdelegate create_custom(spec, custom),
    to: Specable
end
