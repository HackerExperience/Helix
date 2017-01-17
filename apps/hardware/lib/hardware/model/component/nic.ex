defmodule Helix.Hardware.Model.Component.NIC do

  use Ecto.Schema

  alias HELL.PK
  alias Helix.Hardware.Model.Component

  import Ecto.Changeset

  @type t :: %__MODULE__{
    nic_id: PK.t,
    downlink: non_neg_integer,
    uplink: non_neg_integer,
    component: Component.t
  }

  @primary_key false
  schema "nics" do
    field :nic_id, PK,
      primary_key: true

    field :downlink, :integer
    field :uplink, :integer

    belongs_to :component, Component,
      foreign_key: :nic_id,
      references: :component_id,
      type: PK,
      define_field: false,
      on_replace: :delete
  end

  @spec create_changeset(%{any => any}) :: Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, [:nic_id])
    |> changeset(params)
  end

  @spec update_changeset(t | Ecto.Changeset.t, %{any => any}) :: Ecto.Changeset.t
  def update_changeset(struct, params),
    do: changeset(struct, params)

  @spec changeset(t | Ecto.Changeset.t, %{any => any}) :: Ecto.Changeset.t
  def changeset(struct, params) do
    struct
    |> cast(params, [:downlink, :uplink])
    |> validate()
  end

  @spec validate(Ecto.Changeset.t) :: Ecto.Changeset.t
  defp validate(changeset) do
    changeset
    |> validate_required([:downlink, :uplink])
    |> validate_number(:downlink, greater_than_or_equal_to: 0)
    |> validate_number(:uplink, greater_than_or_equal_to: 0)
  end

  defmodule Query do

    alias Helix.Hardware.Model.Component.NIC

    import Ecto.Query, only: [where: 3]

    @spec from_component_ids([HELL.PK.t]) :: Ecto.Queryable.t
    @spec from_component_ids(Ecto.Queryable.t, [HELL.PK.t]) :: Ecto.Queryable.t
    def from_component_ids(query \\ NIC, component_ids) do
      where(query, [n], n.nic_id in ^component_ids)
    end
  end
end