defmodule Helix.Hardware.Model.Component.RAM do

  use Ecto.Schema

  alias HELL.PK
  alias Helix.Hardware.Model.Component
  alias Helix.Hardware.Model.ComponentSpec

  import Ecto.Changeset

  @behaviour Helix.Hardware.Model.ComponentSpec

  @type t :: %__MODULE__{
  }

  @primary_key false
  schema "rams" do
    field :ram_id, PK,
      primary_key: true

    field :ram_size, :integer

    belongs_to :component, Component,
      foreign_key: :ram_id,
      references: :component_id,
      type: PK,
      define_field: false,
      on_replace: :delete
  end

  @spec create_from_spec(ComponentSpec.t) :: Ecto.Changeset.t
  def create_from_spec(cs = %ComponentSpec{spec: spec}) do
    params = Map.take(spec, ["ram_size"])
    ram_id = PK.pk_for(__MODULE__)
    component = Component.create_from_spec(cs, ram_id)

    %__MODULE__{}
    |> changeset(params)
    |> put_change(:ram_id, ram_id)
    |> put_assoc(:component, component)
  end

  @spec update_changeset(t | Ecto.Changeset.t, %{any => any}) :: Ecto.Changeset.t
  def update_changeset(struct, params),
    do: changeset(struct, params)

  @spec changeset(t | Ecto.Changeset.t, %{any => any}) ::
    Ecto.Changeset.t
  def changeset(struct, params) do
    struct
    |> cast(params, [:ram_size])
    |> validate_required(:ram_size)
    |> validate_number(:ram_size, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:ram_id, name: :rams_ram_id_fkey)
  end

  @spec validate_spec(%{:clock => non_neg_integer, :ram_size => non_neg_integer, optional(any) => any}) :: Ecto.Changeset.t
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

    alias Helix.Hardware.Model.Component.RAM

    import Ecto.Query, only: [where: 3]

    @spec from_component_ids([HELL.PK.t]) :: Ecto.Queryable.t
    @spec from_component_ids(Ecto.Queryable.t, [HELL.PK.t]) :: Ecto.Queryable.t
    def from_component_ids(query \\ RAM, component_ids) do
      where(query, [r], r.ram_id in ^component_ids)
    end
  end
end
