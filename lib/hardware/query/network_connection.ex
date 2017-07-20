defmodule Helix.Hardware.Query.NetworkConnection do

  alias HELL.IPv4
  alias Helix.Network.Model.Network
  alias Helix.Server.Model.Server
  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Hardware.Model.Component.NIC
  alias Helix.Hardware.Model.MotherboardSlot
  alias Helix.Hardware.Model.NetworkConnection
  alias Helix.Hardware.Query.Component, as: ComponentQuery
  alias Helix.Hardware.Query.Motherboard, as: MotherboardQuery
  alias Helix.Hardware.Repo

  # FIXME: Think this belongs somewhere else but in the current chaos, it'll be
  #   left here for some time
  @spec get_server_by_ip(Network.id, IPv4.t) ::
    Server.t
    | nil
  def get_server_by_ip(network_id, ip) do
    query = [network_id: network_id, ip: ip]

    with \
      net = %{} <- Repo.get_by(NetworkConnection, query),
      nic = %{} <- net |> Repo.preload(:nic) |> Map.fetch!(:nic),
      # Everything is terrible
      slot = %{} <- Repo.get_by(MotherboardSlot, link_component_id: nic.nic_id),
      # Everything gets terrible-er
      server = %{} <- ServerQuery.fetch_by_motherboard(slot.motherboard_id)
    do
      server
    end
  end

  @spec get_server_ip(Server.id, Network.id) ::
    IPv4.t
    | nil
  def get_server_ip(server_id, network_id) do

    with \
      %{motherboard_id: m} when not is_nil(m) <- ServerQuery.fetch(server_id),
      component = %{} <- ComponentQuery.fetch(m),
      motherboard = %{} <- MotherboardQuery.fetch!(component),
      slots = [_|_] <- MotherboardQuery.get_slots(motherboard),
      nics = [_|_] <- Enum.filter(slots, &(&1.link_component_type == :nic)),
      nics = [_|_] <- Enum.reject(nics, &is_nil(&1.link_component_id)),
      nics = [_|_] <- Enum.map(nics, &Repo.get(NIC, &1.link_component_id)),
      nets = [_|_] <- Enum.map(
        nics,
        &Repo.get(NetworkConnection, &1.network_connection_id)),
      %{ip: ip} <- Enum.find(nets, &(&1.network_id == network_id))
    do
      ip
    else
      _ ->
        nil
    end
  end
end
