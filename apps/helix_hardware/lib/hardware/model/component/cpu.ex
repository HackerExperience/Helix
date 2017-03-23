defmodule Helix.Hardware.Model.Component.CPU do

  use Ecto.Schema

  alias HELL.PK
  alias Helix.Hardware.Model.Component
  alias Helix.Hardware.Model.ComponentSpec

  import Ecto.Changeset

  @behaviour Helix.Hardware.Model.ComponentSpec

  @type t :: %__MODULE__{
  }

  @primary_key false
  schema "cpus" do
    field :cpu_id, PK,
      primary_key: true

    field :clock, :integer
    field :cores, :integer,
      default: 1

    belongs_to :component, Component,
      foreign_key: :cpu_id,
      references: :component_id,
      type: PK,
      define_field: false,
      on_replace: :delete
  end

  @spec create_from_spec(ComponentSpec.t) :: Ecto.Changeset.t
  def create_from_spec(cs = %ComponentSpec{spec: spec}) do
    cpu_id = PK.pk_for(__MODULE__)
    params = Map.take(spec, ["clock", "cores"])

    component = Component.create_from_spec(cs, cpu_id)

    %__MODULE__{}
    |> changeset(params)
    |> put_change(:cpu_id, cpu_id)
    |> put_assoc(:component, component)
  end

  @spec update_changeset(t | Ecto.Changeset.t, %{any => any}) ::
    Ecto.Changeset.t
  def update_changeset(struct, params),
    do: changeset(struct, params)

  @spec changeset(t | Ecto.Changeset.t, %{any => any}) ::
    Ecto.Changeset.t
  def changeset(struct, params) do
    struct
    |> cast(params, [:clock, :cores])
    |> validate_required([:clock, :cores])
    |> validate_number(:clock, greater_than_or_equal_to: 0)
    |> validate_number(:cores, greater_than_or_equal_to: 1)
    |> foreign_key_constraint(:cpu_id, name: :cpus_cpu_id_fkey)
  end

  @spec validate_spec(%{:clock => non_neg_integer, :cores => pos_integer, optional(any) => any}) :: Ecto.Changeset.t
  @doc false
  def validate_spec(params) do
    data = %{
      clock: nil,
      cores: nil
    }
    types = %{
      clock: :integer,
      cores: :integer
    }

    {data, types}
    |> cast(params, [:clock, :cores])
    |> validate_required([:clock, :cores])
    |> validate_number(:clock, greater_than_or_equal_to: 0)
    |> validate_number(:cores, greater_than_or_equal_to: 1)
  end

  defmodule Query do

    alias Helix.Hardware.Model.Component.CPU

    import Ecto.Query, only: [where: 3]

    @spec from_component_ids([HELL.PK.t]) :: Ecto.Queryable.t
    @spec from_component_ids(Ecto.Queryable.t, [HELL.PK.t]) :: Ecto.Queryable.t
    def from_component_ids(query \\ CPU, component_ids) do
      where(query, [c], c.cpu_id in ^component_ids)
    end
  end
end
