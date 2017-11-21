defmodule Helix.Network.Model.Network.Connection do

  use Ecto.Schema

  import Ecto.Changeset
  import HELL.Ecto.Macros

  alias HELL.IPv4
  alias Helix.Server.Model.Component
  alias Helix.Network.Model.Network

  @type t :: term

  @creation_fields [:network_id, :ip, :nic_id]
  @required_fields [:network_id, :ip, :nic_id]

  @primary_key false
  schema "network_connections" do
    field :network_id, Network.ID,
      primary_key: true
    field :ip, IPv4,
      primary_key: true

    field :nic_id, Component.ID
  end

  def create_changeset(network = %Network{}, ip, nic),
    do: create_changeset(network.network_id, ip, nic)
  def create_changeset(network, ip, nic = %Component{}),
    do: create_changeset(network, ip, nic.component_id)
  def create_changeset(network_id = %Network.ID{}, ip, nic_id) do
    params =
      %{
        network_id: network_id,
        ip: ip,
        nic_id: nic_id
      }

    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(@required_fields)
  end

  def update_nic(nc = %__MODULE__{}, nic = %Component{}) do
    nc
    |> change
    |> put_change(:nic_id, nic.component_id)
    |> validate_required(@required_fields)
  end

  def update_ip(nc = %__MODULE__{}, new_ip) do
    nc
    |> change
    |> put_change(:ip, new_ip)
    |> validate_required(@required_fields)
  end

  query do

    alias Helix.Network.Model.Network

    def by_nip(query \\ Network.Connection, network_id, ip),
      do: where(query, [nc], nc.network_id == ^network_id and nc.ip == ^ip)

    def by_nic(query \\ Network.Connection, nic_id),
      do: where(query, [nc], nc.nic_id == ^nic_id)
  end
end
