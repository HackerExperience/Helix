defmodule Helix.Hardware.Model.NetworkConnection do

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias HELL.IPv4
  alias HELL.PK
  alias Helix.Hardware.Model.Component.NIC


  @type id :: PK.t
  @type t :: %__MODULE__{
    network_connection_id: PK.t,
    network_id: PK.t,
    downlink: non_neg_integer,
    uplink: non_neg_integer,
    nic: NIC.t
  }

  @one_ip_per_network_index :network_connections_network_id_ip_unique_index

  @primary_key false
  @ecto_autogenerate {
    :network_connection_id,
    {PK, :pk_for, [:hardware_network_connection]}
  }
  schema "network_connections" do
    field :network_connection_id, PK,
      primary_key: true

    field :network_id, PK

    field :ip, IPv4

    field :downlink, :integer
    field :uplink, :integer

    has_one :nic, NIC,
      foreign_key: :network_connection_id,
      references: :network_connection_id,
      on_delete: :nilify_all
  end

  @spec create_changeset(map) ::
    Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, [:network_id])
    |> put_change(:ip, IPv4.autogenerate())
    |> changeset(params)
  end

  @spec update_changeset(t | Changeset.t, map) ::
    Changeset.t
  def update_changeset(struct, params),
    do: changeset(struct, params)

  @spec changeset(t | Changeset.t, map) ::
    Changeset.t
  def changeset(struct, params) do
    struct
    |> cast(params, [:ip, :downlink, :uplink])
    |> validate_required([:ip, :network_id, :downlink, :uplink])
    |> validate_number(:downlink, greater_than_or_equal_to: 0)
    |> validate_number(:uplink, greater_than_or_equal_to: 0)
    |> unique_constraint(:ip, name: @one_ip_per_network_index)
  end

  defmodule Query do

    alias Helix.Hardware.Model.NetworkConnection

    import Ecto.Query, only: [where: 3]

    @spec by_id(Ecto.Queryable.t, NetworkConnection.id) :: Ecto.Queryable.t
    def by_id(query \\ NetworkConnection, nc_id),
      do: where(query, [nc], nc.network_connection_id == ^nc_id)

    @spec by_nip(Ecto.Queryable.t, PK.t, IPv4.t) :: Ecto.Queryable.t
    def by_nip(query \\ NetworkConnection, network_id, ip),
      do: where(query, [nc], nc.network_id == ^network_id and nc.ip == ^ip)
  end
end
