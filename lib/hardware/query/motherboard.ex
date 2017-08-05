defmodule Helix.Hardware.Query.Motherboard do

  alias Helix.Network.Model.Network
  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Hardware.Model.Component
  alias Helix.Hardware.Model.Motherboard
  alias Helix.Hardware.Model.MotherboardSlot
  alias Helix.Hardware.Model.NetworkConnection
  alias Helix.Hardware.Internal.Motherboard, as: MotherboardInternal

  @spec fetch(Component.idt) ::
    Motherboard.t
    | nil
  @doc """
  Fetches a motherboard by component
  """
  defdelegate fetch(component),
    to: MotherboardInternal

  @spec fetch_by_nip(Network.id, NetworkConnection.ip) ::
    Motherboard.t
    | nil
  defdelegate fetch_by_nip(network_id, ip),
    to: MotherboardInternal

  # TODO: Remove \/
  defdelegate preload_components(mobo),
    to: MotherboardInternal

  @spec get_slots(Motherboard.t | Component.idt) ::
    [MotherboardSlot.t]
  @doc """
  Gets every slot from a motherboard
  """
  defdelegate get_slots(motherboard),
    to: MotherboardInternal

  @spec resources(Motherboard.t) ::
    %{
      cpu: non_neg_integer,
      hdd: non_neg_integer,
      ram: non_neg_integer,
      net: %{String.t => %{uplink: non_neg_integer, downlink: non_neg_integer}}
    }
  defdelegate resources(motherboard),
    to: MotherboardInternal

  @spec get_networks(Motherboard.t | Motherboard.id) ::
    [NetworkConnection.t]
  defdelegate get_networks(motherboard),
    to: MotherboardInternal

  # TODO: Test, type, doc
  def is_attached?(motherboard) do
    ServerQuery.fetch_by_motherboard(motherboard)
    && true
    || false
  end
end
