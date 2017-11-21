defmodule Helix.Network.Internal.Network.Connection do

  alias Helix.Server.Model.Component
  alias Helix.Network.Model.Network
  alias Helix.Network.Repo

  def fetch(network_id, ip) do
    network_id
    |> Network.Connection.Query.by_nip(ip)
    |> Repo.one()
  end

  def fetch_by_nic(nic) do
    nic
    |> Network.Connection.Query.by_nic()
    |> Repo.one()
  end

  def create(network = %Network{}, ip, nic = %Component{}) do
    network
    |> Network.Connection.create_changeset(ip, nic)
    |> Repo.insert()
  end

  def update_nic(nc = %Network.Connection{}, new_nic = %Component{}) do
    nc
    |> Network.Connection.update_nic(new_nic)
    |> Repo.update()
  end

  def update_ip(nc = %Network.Connection{}, new_ip) do
    nc
    |> Network.Connection.update_ip(new_ip)
    |> Repo.update()
  end

  def delete(nc = %Network.Connection{}) do
    nc
    |> Repo.delete()

    :ok
  end
end
