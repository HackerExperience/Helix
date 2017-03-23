defmodule Helix.Hardware.Model.Component.HDD do

  use Ecto.Schema

  alias HELL.PK
  alias Helix.Hardware.Model.Component
  alias Helix.Hardware.Model.ComponentSpec

  import Ecto.Changeset

  @behaviour Helix.Hardware.Model.ComponentSpec

  @type t :: %__MODULE__{
  }

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

  @spec create_from_spec(ComponentSpec.t) :: Ecto.Changeset.t
  def create_from_spec(cs = %ComponentSpec{spec: spec}) do
    hdd_id = PK.pk_for(__MODULE__)
    params = Map.take(spec, ["hdd_size"])
    component = Component.create_from_spec(cs, hdd_id)

    %__MODULE__{}
    |> changeset(params)
    |> put_change(:hdd_id, hdd_id)
    |> put_assoc(:component, component)
  end

  @spec update_changeset(t | Ecto.Changeset.t, %{any => any}) :: Ecto.Changeset.t
  def update_changeset(struct, params),
    do: changeset(struct, params)

  @spec changeset(t | Ecto.Changeset.t, %{any => any}) ::
    Ecto.Changeset.t
  def changeset(struct, params) do
    struct
    |> cast(params, [:hdd_size])
    |> validate_required([:hdd_size])
    |> validate_number(:hdd_size, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:hdd_id, name: :hdds_hdd_id_fkey)
  end

  @spec validate_spec(%{size: non_neg_integer}) :: Ecto.Changeset.t
  @doc false
  def validate_spec(params) do
    data = %{
      hdd_size: nil
    }
    types = %{
      hdd_size: :integer
    }

    {data, types}
    |> cast(translate_from_spec_to_schema_keys(params), [:hdd_size])
    |> validate_required([:hdd_size])
    |> validate_number(:hdd_size, greater_than_or_equal_to: 0)
  end

  @spec translate_from_spec_to_schema_keys(map) :: %{hdd_size: term}
  defp translate_from_spec_to_schema_keys(params) do
    params
    |> Enum.map(fn
      {:size, x} ->
        {:hdd_size, x}
      {"size", x} ->
        {"hdd_size", x}
      kv ->
        kv
    end)
    |> :maps.from_list()
  end

  defmodule Query do

    alias Helix.Hardware.Model.Component.HDD

    import Ecto.Query, only: [where: 3]

    @spec from_component_ids([HELL.PK.t]) :: Ecto.Queryable.t
    @spec from_component_ids(Ecto.Queryable.t, [HELL.PK.t]) :: Ecto.Queryable.t
    def from_component_ids(query \\ HDD, component_ids) do
      where(query, [h], h.hdd_id in ^component_ids)
    end
  end
end
