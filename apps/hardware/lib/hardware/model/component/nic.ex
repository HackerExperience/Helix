defmodule Helix.Hardware.Model.Component.NIC do

  use Ecto.Schema

  alias HELL.PK
  alias HELL.MacAddress
  alias Helix.Hardware.Model.Component
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

  # REVIEW: have a service that provides unique MacAddresses or just
  #   autogenerate them hoping for no conflict ?
  @spec create_changeset(%{any => any}) :: Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, [:nic_id])
    |> put_change(:mac_address, MacAddress.generate())
    |> validate_required([:nic_id, :mac_address])
    |> changeset(params)
  end

  @spec update_changeset(t | Ecto.Changeset.t, %{any => any}) :: Ecto.Changeset.t
  def update_changeset(struct, params),
    do: changeset(struct, params)

  @spec changeset(t | Ecto.Changeset.t, %{any => any}) :: Ecto.Changeset.t
  def changeset(struct, params) do
    struct
    |> cast(params, [:network_connection_id])
    |> foreign_key_constraint(:nic_id, name: :nics_nic_id_fkey)
    |> foreign_key_constraint(:network_connection_id, name: :nics_network_connection_id_fkey)
    |> unique_constraint(:mac_address, name: :nics_mac_address_index)
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