defmodule Helix.Hardware.Model.Component.RAM do

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias Helix.Hardware.Model.Component
  alias Helix.Hardware.Model.ComponentSpec

  @behaviour Helix.Hardware.Model.ComponentSpec

  @type id :: Component.id
  @type t :: %__MODULE__{
    ram_id: id,
    ram_size: non_neg_integer,
    component: term
  }

  @primary_key false
  schema "rams" do
    field :ram_id, Component.ID,
      primary_key: true

    field :ram_size, :integer

    belongs_to :component, Component,
      foreign_key: :ram_id,
      references: :component_id,
      define_field: false,
      on_replace: :delete
  end

  @spec create_from_spec(ComponentSpec.t) ::
    Changeset.t
  def create_from_spec(cs = %ComponentSpec{spec: spec}) do
    params = Map.take(spec, ["ram_size"])

    component = Component.create_from_spec(cs)

    %__MODULE__{}
    |> changeset(params)
    |> put_assoc(:component, component)
  end

  @spec update_changeset(t | Changeset.t, map) ::
    Changeset.t
  def update_changeset(struct, params),
    do: changeset(struct, params)

  @spec changeset(t | Changeset.t, map) ::
    Changeset.t
  def changeset(struct, params) do
    struct
    |> cast(params, [:ram_size])
    |> validate_required(:ram_size)
    |> validate_number(:ram_size, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:ram_id, name: :rams_ram_id_fkey)
  end

  @spec validate_spec(%{:clock => non_neg_integer, :ram_size => non_neg_integer, optional(any) => any}) ::
    Changeset.t
  @doc false
  def validate_spec(params) do
    data = %{
      clock: nil,
      ram_size: nil
    }
    types = %{
      clock: :integer,
      ram_size: :integer
    }

    {data, types}
    |> cast(params, [:clock, :ram_size])
    |> validate_required([:clock, :ram_size])
    |> validate_number(:clock, greater_than_or_equal_to: 0)
    |> validate_number(:ram_size, greater_than_or_equal_to: 0)
  end

  defmodule Query do
    import Ecto.Query

    alias Ecto.Queryable
    alias Helix.Hardware.Model.Component
    alias Helix.Hardware.Model.Component.RAM

    @spec from_components_ids(Queryable.t, [Component.id]) ::
      Queryable.t
    def from_components_ids(query \\ RAM, components_ids),
      do: where(query, [r], r.ram_id in ^components_ids)

    def by_component(query \\ RAM, id),
      do: where(query, [r], r.ram_id == ^id)
  end
end
