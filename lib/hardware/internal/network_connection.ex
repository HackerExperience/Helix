defmodule Helix.Hardware.Internal.NetworkConnection do

  # TODO: Test + doc

  alias Helix.Cache.Action.Cache, as: CacheAction
  alias Helix.Network.Model.Network
  alias Helix.Hardware.Model.Component
  alias Helix.Hardware.Model.NetworkConnection
  alias Helix.Hardware.Repo

  @spec fetch(NetworkConnection.id) ::
    NetworkConnection.t
    | nil
  def fetch(id),
    do: Repo.get(NetworkConnection, id)

  @spec fetch_by_nip(Network.id, NetworkConnection.ip) ::
    NetworkConnection.t
    | nil
  def fetch_by_nip(network_id, ip) do
    network_id
    |> NetworkConnection.Query.by_nip(ip)
    |> Repo.one()
  end

  @spec get_nic(NetworkConnection.t | NetworkConnection.id) ::
    Component.t
    | nil
  def get_nic(network_connection = %NetworkConnection{}) do
    network_connection
    |> Repo.preload(:nic)
    |> Map.get(:nic)
    |> Repo.preload(:component)
    |> Map.get(:component)
    end
  def get_nic(network_connection_id) do
    network_connection = fetch(network_connection_id)
    if network_connection do
      get_nic(network_connection)
    else
      nil
    end
  end

  @spec update_ip(NetworkConnection.t | NetworkConnection.id, NetworkConnection.ip) ::
    {:ok, NetworkConnection}
    | {:error, Ecto.Changeset.t}
  def update_ip(nc = %NetworkConnection{}, new_ip) do
    result =
      nc
      |> NetworkConnection.update_changeset(%{ip: new_ip})
      |> Repo.update()

    with {:ok, _} <- result do
      CacheAction.purge_nip(nc.network_id, nc.ip)
      CacheAction.update_nip(nc.network_id, new_ip)
    end

    result
  end
  def update_ip(network_connection_id, ip) do
    network_connection_id
    |> fetch()
    |> update_ip(ip)
  end
end
