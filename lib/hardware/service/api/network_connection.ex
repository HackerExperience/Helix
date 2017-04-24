defmodule Helix.Hardware.Service.API.NetworkConnection do

  alias Helix.Server.Service.API.Server, as: ServerAPI
  alias Helix.Hardware.Model.NetworkConnection
  alias Helix.Hardware.Model.MotherboardSlot
  alias Helix.Hardware.Repo

  # FIXME: Think this belongs somewhere else but in the current chaos, it'll be
  #   left here for some time
  @spec get_server_by_ip(HELL.PK.t, HELL.IPv4.t) ::
    Helix.Server.Model.Server.t
    | nil
  def get_server_by_ip(network_id, ip) do
    query = [network_id: network_id, ip: ip]

    with \
      net = %{} <- Repo.get_by(NetworkConnection, query),
      nic = %{} <- net |> Repo.preload(:nic) |> Map.fetch!(:nic),
      # Everything is terrible
      slot = %{} <- Repo.get_by(MotherboardSlot, link_component_id: nic.nic_id),
      # Everything gets terrible-er
      server = %{} <- ServerAPI.fetch_by_motherboard(slot.motherboard_id)
    do
      server
    end
  end

  @spec get_server_ip(HELL.PK.t, HELL.PK.t) ::
    HELL.IPv4.t
    | nil
  def get_server_ip(server_id, network_id) do
    alias Helix.Server.Service.API.Server
    alias Helix.Hardware.Model.Component.NIC
    alias Helix.Hardware.Model.NetworkConnection
    alias Helix.Hardware.Service.API.Component
    alias Helix.Hardware.Service.API.Motherboard

    with \
      %{motherboard_id: m} when not is_nil(m) <- Server.fetch(server_id),
      component = %{} <- Component.fetch(m),
      motherboard = %{} <- Motherboard.fetch!(component),
      slots = [_|_] <- Motherboard.get_slots(motherboard),
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
