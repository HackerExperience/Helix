defmodule Helix.Hardware.Internal.NetworkConnection do

  alias Helix.Cache.Action.Cache, as: CacheAction
  alias Helix.Network.Model.Network
  alias Helix.Hardware.Model.NetworkConnection
  alias Helix.Hardware.Repo

  @spec fetch(NetworkConnection.id) ::
    NetworkConnection.t
    | nil
  def fetch(network_connection_id) do
    network_connection_id
    |> NetworkConnection.Query.by_id()
    |> Repo.one()
  end

  @spec fetch_by_nip(Network.id, NetworkConnection.ip) ::
    NetworkConnection.t
    | nil
  def fetch_by_nip(network_id, ip) do
    network_id
    |> NetworkConnection.Query.by_nip(ip)
    |> Repo.one()
  end

  @spec update_ip(NetworkConnection.t | NetworkConnection.id, NetworkConnection.ip) ::
    {:ok, NetworkConnection}
    | {:error, Ecto.Changeset.t}
  def update_ip(nc = %NetworkConnection{}, ip) do
    result =
      nc
      |> NetworkConnection.update_changeset(%{ip: ip})
      |> Repo.update()

    with {:ok, _} <- result do
      CacheAction.purge_nip(nc.network_id, nc.ip)
      CacheAction.update_nip(nc.network_id, ip)
    end

    result
  end

  def update_ip(network_connection_id, ip) do
    network_connection_id
    |> fetch()
    |> update_ip(ip)
  end
end
