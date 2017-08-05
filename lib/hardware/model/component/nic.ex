defmodule Helix.Hardware.Model.Component.NIC do

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias HELL.MacAddress
  alias Helix.Hardware.Model.Component
  alias Helix.Hardware.Model.ComponentSpec
  alias Helix.Hardware.Model.NetworkConnection

  @behaviour Helix.Hardware.Model.ComponentSpec

  @type id :: Component.id
  @type t :: %__MODULE__{
    nic_id: id,
    mac_address: MacAddress.t,
    network_connection_id: NetworkConnection.id,
    component: term,
    network_connection: term
  }

  @primary_key false
  schema "nics" do
    field :nic_id, Component.ID,
      primary_key: true

    field :network_connection_id, NetworkConnection.ID

    field :mac_address, MacAddress

    belongs_to :component, Component,
      foreign_key: :nic_id,
      references: :component_id,
      define_field: false,
      on_replace: :delete
    belongs_to :network_connection, NetworkConnection,
      foreign_key: :network_connection_id,
      references: :network_connection_id,
      define_field: false,
      on_replace: :nilify
  end

  @spec create_from_spec(ComponentSpec.t) ::
    Changeset.t
  def create_from_spec(cs = %ComponentSpec{spec: _}) do
    component = Component.create_from_spec(cs)

    %__MODULE__{}
    |> changeset(%{})
    # REVIEW: have a service that provides unique MacAddresses or just
    #   autogenerate them hoping for no conflict ?
    |> put_change(:mac_address, MacAddress.generate())
    |> put_assoc(:component, component)
  end

  @spec update_changeset(t | Changeset.t, map) ::
    Changeset.t
  def update_changeset(struct, params),
    do: changeset(struct, params)

  @spec changeset(%__MODULE__{} | Changeset.t, map) ::
    Changeset.t
  def changeset(struct, params) do
    struct
    |> cast(params, [:network_connection_id])
    |> foreign_key_constraint(:nic_id)
    |> foreign_key_constraint(:network_connection_id)
    |> unique_constraint(:mac_address)
  end

  @spec validate_spec(%{:link => non_neg_integer, optional(any) => any}) ::
    Changeset.t
  @doc false
  def validate_spec(params) do
    data = %{
      link: nil
    }
    types = %{
      link: :integer
    }

    {data, types}
    |> cast(params, [:link])
    |> validate_required([:link])
    |> validate_number(:link, greater_than_or_equal_to: 0)
  end

  defmodule Query do
    import Ecto.Query

    alias Ecto.Queryable
    alias Helix.Hardware.Model.Component
    alias Helix.Hardware.Model.Component.NIC

    @spec from_components_ids(Queryable.t, [Component.idtb]) ::
      Queryable.t
    def from_components_ids(query \\ NIC, components_ids),
      do: where(query, [n], n.nic_id in ^components_ids)

    # REVIEW: rename this ?
    @spec inner_join_network_connection(Queryable.t) ::
      Queryable.t
    def inner_join_network_connection(query \\ NIC) do
      query
      |> join(:inner, [n], nc in assoc(n, :network_connection))
      |> preload([n, ..., nc], network_connection: nc)
    end

    @spec by_component(Queryable.t, Component.idtb) ::
      Queryable.t
    def by_component(query \\ NIC, id),
      do: where(query, [n], n.nic_id == ^id)
  end
end
