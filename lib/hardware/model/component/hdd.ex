defmodule Helix.Hardware.Model.Component.HDD do

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias HELL.PK
  alias Helix.Hardware.Model.Component
  alias Helix.Hardware.Model.ComponentSpec

  @behaviour Helix.Hardware.Model.ComponentSpec

  @type t :: %__MODULE__{}

  @primary_key false
  schema "hdds" do
    field :hdd_id, PK,
      primary_key: true

    field :hdd_size, :integer

    belongs_to :component, Component,
      foreign_key: :hdd_id,
      references: :component_id,
      type: PK,
      define_field: false,
      on_replace: :delete
  end

  @spec create_from_spec(ComponentSpec.t) ::
    Changeset.t
  def create_from_spec(cs = %ComponentSpec{spec: spec}) do
    hdd_id = PK.pk_for(:hardware_component_hdd)
    params = Map.take(spec, ["hdd_size"])
    component = Component.create_from_spec(cs, hdd_id)

    %__MODULE__{}
    |> changeset(params)
    |> put_change(:hdd_id, hdd_id)
    |> put_assoc(:component, component)
  end

  @spec update_changeset(t | Changeset.t, %{any => any}) ::
    Changeset.t
  def update_changeset(struct, params),
    do: changeset(struct, params)

  @spec changeset(t | Changeset.t, %{any => any}) ::
    Changeset.t
  def changeset(struct, params) do
    struct
    |> cast(params, [:hdd_size])
    |> validate_required([:hdd_size])
    |> validate_number(:hdd_size, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:hdd_id, name: :hdds_hdd_id_fkey)
  end

  @spec validate_spec(%{:hdd_size => non_neg_integer, optional(any) => any}) ::
    Changeset.t
  @doc false
  def validate_spec(params) do
    data = %{
      hdd_size: nil
    }
    types = %{
      hdd_size: :integer
    }

    {data, types}
    |> cast(params, [:hdd_size])
    |> validate_required([:hdd_size])
    |> validate_number(:hdd_size, greater_than_or_equal_to: 0)
  end

  defmodule Query do

    import Ecto.Query, only: [where: 3]

    alias Ecto.Queryable
    alias Helix.Hardware.Model.Component
    alias Helix.Hardware.Model.Component.HDD

    @spec from_component_ids([Component.id]) ::
      Queryable.t
    @spec from_component_ids(Queryable.t, [Component.id]) ::
      Queryable.t
    def from_component_ids(query \\ HDD, component_ids),
      do: where(query, [h], h.hdd_id in ^component_ids)
  end
end
