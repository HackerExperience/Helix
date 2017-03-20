defmodule Helix.Hardware.Model.NetworkConnection do

  use Ecto.Schema

  alias HELL.IPv4
  alias HELL.PK
  alias Helix.Hardware.Model.Component.NIC

  import Ecto.Changeset

  @type t :: %__MODULE__{
    network_connection_id: PK.t,
    network_id: PK.t,
    downlink: non_neg_integer,
    uplink: non_neg_integer,
    nic: NIC.t
  }

  @primary_key false
  @ecto_autogenerate {:network_conections, {PK, :pk_for, [__MODULE__]}}
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

  @spec create_changeset(%{}) :: Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, [:network_id])
    |> put_change(:ip, IPv4.autogenerate())
    |> changeset(params)
  end

  @spec update_changeset(t | Ecto.Changeset.t, %{}) :: Ecto.Changeset.t
  def update_changeset(struct, params),
    do: changeset(struct, params)

  @spec changeset(t | Ecto.Changeset.t, %{}) :: Ecto.Changeset.t
  def changeset(struct, params) do
    struct
    |> cast(params, [:ip, :downlink, :uplink])
    |> validate_required([:ip, :network_id, :downlink, :uplink])
    |> validate_number(:downlink, greater_than_or_equal_to: 0)
    |> validate_number(:uplink, greater_than_or_equal_to: 0)
    |> unique_constraint(:ip, name: :network_connections_network_id_ip_unique_index)
  end
end