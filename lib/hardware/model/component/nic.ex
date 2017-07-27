defmodule Helix.Hardware.Model.Component.NIC do

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias HELL.PK
  alias HELL.MacAddress
  alias Helix.Hardware.Model.Component
  alias Helix.Hardware.Model.ComponentSpec
  alias Helix.Hardware.Model.NetworkConnection

  @behaviour Helix.Hardware.Model.ComponentSpec

  @type t :: %__MODULE__{
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

  @spec create_from_spec(ComponentSpec.t) ::
    Changeset.t
  def create_from_spec(cs = %ComponentSpec{spec: _}) do
    nic_id = PK.pk_for(:hardware_component_nic)
    component = Component.create_from_spec(cs, nic_id)

    %__MODULE__{}
    |> changeset(%{})
    # REVIEW: have a service that provides unique MacAddresses or just
    #   autogenerate them hoping for no conflict ?
    |> put_change(:mac_address, MacAddress.generate())
    |> put_change(:nic_id, nic_id)
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

    import Ecto.Query, only: [join: 4, preload: 3, where: 3]

    alias Ecto.Queryable
    alias Helix.Hardware.Model.Component
    alias Helix.Hardware.Model.Component.NIC

    @spec from_components_ids([Component.id]) ::
      Queryable.t
    @spec from_components_ids(Queryable.t, [Component.id]) ::
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
  end
end
