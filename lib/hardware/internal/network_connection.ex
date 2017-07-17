defmodule Helix.Hardware.Internal.NetworkConnection do

  alias HELL.Constant
  alias Helix.Cache.Action.Cache, as: CacheAction
  alias Helix.Hardware.Model.NetworkConnection
  alias Helix.Hardware.Repo

  def fetch(network_connection_id) do
    network_connection_id
    |> NetworkConnection.Query.by_id()
    |> Repo.one()
  end

  def fetch_by_nip(network_id, ip) do
    NetworkConnection.Query.by_nip(network_id, ip)
    |> Repo.one()
  end

  def update_ip(nc_id, ip) when is_binary(nc_id) do
    nc_id
    |> fetch()
    |> update_ip(ip)
  end
  def update_ip(nc = %NetworkConnection{}, ip) do
    result = nc
    |> NetworkConnection.update_changeset(%{ip: ip})
    |> Repo.update()

    case result do
      {:ok, _} ->
        CacheAction.purge_nip(nc.network_id, nc.ip)
        CacheAction.purge_nip(nc.network_id, ip)
        result
      _ ->
        result
    end
  end
end
