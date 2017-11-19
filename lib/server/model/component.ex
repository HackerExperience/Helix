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

  @type t :: term

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

  @doc """
  Recovers internal Elixir/Erlang/Helix format.
  """
  def format(component = %Component{}) do
    %{component|
      custom: Specable.format_custom(component)
    }
  end

  def create_from_spec(spec = %Component.Spec{}) do
    params =
      %{
        type: spec.component_type,
        spec_id: spec.spec_id,
        custom: Component.Spec.get_custom(spec)
      }

    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(@required_fields)
  end

  defdelegate get_resources(component),
    to: Componentable

  query do

    def by_id(query \\ Component, component_id),
      do: where(query, [c], c.component_id == ^component_id)
  end
end
