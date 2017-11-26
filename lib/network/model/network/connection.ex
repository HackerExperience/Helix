defmodule Helix.Network.Model.Network.Connection do
  @moduledoc """
  `Network.Connection` represents a NIP. This NIP may be attached to a NIC.

  A NIP (NetworkConnection) is only valid when attached to a NIC that is
  attached to a motherboard. Otherwise, the NetworkConnection still exists but
  is deemed "unassigned".

  NetworkConnection is part of a user's inventory, hence the `entity_id` field,
  which is used as an identifier (in case there's no NIC assigned to it).
  """

  use Ecto.Schema

  import Ecto.Changeset
  import HELL.Ecto.Macros

  alias Ecto.Changeset
  alias HELL.IPv4
  alias Helix.Entity.Model.Entity
  alias Helix.Server.Model.Component
  alias Helix.Network.Model.Network

  @type t ::
    %__MODULE__{
      network_id: Network.id,
      ip: ip,
      entity_id: Entity.id,
      nic_id: Component.id | nil
    }

  @type changeset :: %Changeset{data: %__MODULE__{}}

  @type ip :: IPv4.t

  @type creation_params ::
    %{
      network_id: Network.idt,
      ip: ip,
      entity_id: Entity.idt,
      nic_id: Component.idt | nil
    }

  @creation_fields [:network_id, :ip, :entity_id, :nic_id]
  @required_fields [:network_id, :ip, :entity_id]

  @primary_key false
  schema "network_connections" do
    field :network_id, Network.ID,
      primary_key: true
    field :ip, IPv4,
      primary_key: true

    field :entity_id, Entity.ID
    field :nic_id, Component.ID,
      default: nil
  end

  @spec create_changeset(creation_params) ::
    changeset
  def create_changeset(params) do

    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(@required_fields)
  end

  @spec update_nic(t, Component.nic) ::
    changeset
  def update_nic(nc = %__MODULE__{}, nic = %Component{type: :nic}) do
    nc
    |> change
    |> put_change(:nic_id, nic.component_id)
    |> validate_required(@required_fields)
  end

  @spec update_ip(t, ip) ::
    changeset
  def update_ip(nc = %__MODULE__{}, new_ip) do
    nc
    |> change
    |> put_change(:ip, new_ip)
    |> validate_required(@required_fields)
  end

  query do

    alias Helix.Server.Model.Component
    alias Helix.Network.Model.Network

    @spec by_nip(Queryable.t, Network.id, Network.Connection.ip) ::
      Queryable.t
    def by_nip(query \\ Network.Connection, network_id, ip),
      do: where(query, [nc], nc.network_id == ^network_id and nc.ip == ^ip)

    @spec by_nic(Queryable.t, Component.id) ::
      Queryable.t
    def by_nic(query \\ Network.Connection, nic_id),
      do: where(query, [nc], nc.nic_id == ^nic_id)
  end
end
