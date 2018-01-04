defmodule Helix.Network.Internal.Network.Connection do

  alias Helix.Cache.Action.Cache, as: CacheAction
  alias Helix.Entity.Model.Entity
  alias Helix.Server.Model.Component
  alias Helix.Network.Model.Network
  alias Helix.Network.Repo

  @typep repo_result ::
    {:ok, Network.Connection.t}
    | {:error, Network.Connection.changeset}

  @spec fetch(Network.id, Network.ip) ::
    Network.Connection.t
    | nil
  def fetch(network_id, ip) do
    network_id
    |> Network.Connection.Query.by_nip(ip)
    |> Repo.one()
  end

  @spec fetch_by_nic(Component.id) ::
    Network.Connection.t
    | nil
  def fetch_by_nic(nic_id) do
    nic_id
    |> Network.Connection.Query.by_nic()
    |> Repo.one()
  end

  @spec get_by_entity(Entity.id) ::
    [Network.Connection.t]
  def get_by_entity(entity_id) do
    entity_id
    |> Network.Connection.Query.by_entity()
    |> Repo.all()
  end

  @spec create(Network.idt, Network.ip, Entity.idt, Component.idt | nil) ::
    repo_result
  @doc """
  Creates a new NetworkConnection. Notice it may not have a NIC assigned to it,
  in which case the NC is said to be "unassigned".
  """
  def create(network_id, ip, entity_id, nic_id \\ nil) do
    params =
      %{
        network_id: network_id,
        ip: ip,
        entity_id: entity_id,
        nic_id: nic_id
      }

    params
    |> Network.Connection.create_changeset()
    |> Repo.insert()
  end

  @spec update_nic(Network.Connection.t, Component.nic | nil) ::
    repo_result
  @doc """
  Updates the NIC assigned to the NetworkConnection
  """
  def update_nic(nc = %Network.Connection{}, new_nic) do
    result =
      nc
      |> Network.Connection.update_nic(new_nic)
      |> Repo.update()

    with {:ok, _} <- result do
      # If `new_nic` is set, we are going from `nil` to `Component.id`, i.e. we
      # are assigning the Network.Connection to the NIC. As such, the NC does
      # not exist on the cache currently, and `update_server_by_nip` would never
      # succeed (as that NIP is not assigned to the server -- on the cache)
      # That's why we need to force a server update using another method, in
      # this case the NIC.
      if new_nic do
        CacheAction.update_server_by_component(new_nic.component_id)

      # On the other hand, if `new_nic` is empty, we are removing a previously
      # existing Network.Connection. So we CAN update the server by the NIP.
      # We must also purge the Network.Connection, as it's no longer in use.
      else
        CacheAction.update_server_by_nip(nc.network_id, nc.ip)
        CacheAction.purge_network(nc.network_id, nc.ip)
      end
    end

    result
  end

  @spec update_ip(Network.Connection.t, Network.ip) ::
    repo_result
  @doc """
  Updates the NetworkConnection IP address.
  """
  def update_ip(nc = %Network.Connection{}, new_ip) do
    result =
      nc
      |> Network.Connection.update_ip(new_ip)
      |> Repo.update()

    with {:ok, _} <- result do
      # Purge previous nip
      CacheAction.purge_network(nc.network_id, nc.ip)

      # Cache new nip
      CacheAction.update_network(nc.network_id, new_ip)
    end

    result
  end

  @spec delete(Network.Connection.t) ::
    :ok
  def delete(nc = %Network.Connection{}) do
    nc
    |> Repo.delete()

    :ok
  end
end
