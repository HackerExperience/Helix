defmodule Helix.Hardware.Model.Component.NIC do

  use Ecto.Schema

  alias HELL.PK
  alias HELL.MacAddress
  alias Helix.Hardware.Model.Component
  alias Helix.Hardware.Model.ComponentSpec
  alias Helix.Hardware.Model.NetworkConnection

  import Ecto.Changeset

  @type t :: %__MODULE__{
    nic_id: PK.t,
    mac_address: MacAddress.t,
    component: Component.t,
    network_connection: NetworkConnection.t,
    network_connection_id: PK.t
  }

  @primary_key false
  schema "nics" do
    field :nic_id, PK,
      primary_key: true

    field :mac_address, MacAddress

    belongs_to :component, Component,
      foreign_key: :nic_id,
      references: :component_id,
      type: PK,
      define_field: false,
      on_replace: :delete
    belongs_to :network_connection, NetworkConnection,
      foreign_key: :network_connection_id,
      references: :network_connection_id,
      type: PK,
      on_replace: :nilify
  end

  @spec create_from_spec(ComponentSpec.t) :: Ecto.Changeset.t
  def create_from_spec(cs = %ComponentSpec{spec: _}) do
    nic_id = PK.pk_for(__MODULE__)
    component = Component.create_from_spec(cs, nic_id)

    %__MODULE__{}
    |> changeset(%{})
    # REVIEW: have a service that provides unique MacAddresses or just
    #   autogenerate them hoping for no conflict ?
    |> put_change(:mac_address, MacAddress.generate())
    |> put_change(:nic_id, nic_id)
    |> put_assoc(:component, component)
  end

  @spec update_changeset(t | Ecto.Changeset.t, %{any => any}) :: Ecto.Changeset.t
  def update_changeset(struct, params),
    do: changeset(struct, params)

  @spec changeset(t | Ecto.Changeset.t, %{any => any}) ::
    Ecto.Changeset.t
  def changeset(struct, params) do
    struct
    |> cast(params, [:network_connection_id])
    |> foreign_key_constraint(:nic_id)
    |> foreign_key_constraint(:network_connection_id)
    |> unique_constraint(:mac_address)
  end

  defmodule Query do

    alias Helix.Hardware.Model.Component.NIC
    alias Helix.Hardware.Model.NetworkConnection

    import Ecto.Query, only: [join: 4, preload: 3, where: 3]

    @spec from_component_ids([HELL.PK.t]) :: Ecto.Queryable.t
    @spec from_component_ids(Ecto.Queryable.t, [HELL.PK.t]) :: Ecto.Queryable.t
    def from_component_ids(query \\ NIC, component_ids) do
      where(query, [n], n.nic_id in ^component_ids)
    end

    # REVIEW: rename this ?
    @spec inner_join_network_connection(Ecto.Queryable.t) :: Ecto.Queryable.t
    def inner_join_network_connection(query \\ NIC) do
      query
      |> join(:inner, [n], nc in assoc(n, :network_connection))
      |> preload([n, ..., nc], network_connection: nc)
    end
  end
end