defmodule Helix.Hardware.Query.Motherboard do

  alias Helix.Server.Model.Server
  alias Helix.Software.Model.Storage
  alias Helix.Network.Model.Network
  alias Helix.Hardware.Model.Component
  alias Helix.Hardware.Model.Motherboard
  alias Helix.Hardware.Model.MotherboardSlot
  alias Helix.Hardware.Model.NetworkConnection
  alias Helix.Hardware.Query.Motherboard.Origin, as: MotherboardQueryOrigin

  @spec fetch(Component.t | Motherboard.id) ::
    Motherboard.t
    | nil
  @doc """
  Fetches a motherboard by component
  """
  defdelegate fetch(component),
    to: MotherboardQueryOrigin

  @spec fetch_by_server(Server.id) ::
    Motherboard.t
    | nil
  defdelegate fetch_by_server(server_id),
    to: MotherboardQueryOrigin

  @spec fetch_by_nip(Network.id, NetworkConnection.ip) ::
    Motherboard.t
    | nil
  defdelegate fetch_by_nip(network_id, ip),
    to: MotherboardQueryOrigin

  @spec get_slots(Motherboard.t | Motherboard.id) ::
    [MotherboardSlot.t]
  @doc """
  Gets every slot from a motherboard
  """
  defdelegate get_slots(motherboard),
    to: MotherboardQueryOrigin

  @spec preload_components(Motherboard.t) ::
    Motherboard.t
  defdelegate preload_components(motherboard),
    to: MotherboardQueryOrigin

  @spec resources(Motherboard.t) ::
    %{
      cpu: non_neg_integer,
      hdd: non_neg_integer,
      ram: non_neg_integer,
      net: %{
        Network.id =>
          %{uplink: non_neg_integer, downlink: non_neg_integer}
          | %{}
      }
    }
  defdelegate resources(motherboard),
    to: MotherboardQueryOrigin

  @spec get_networks(Motherboard.t | Motherboard.id) ::
    [NetworkConnection.t]
  defdelegate get_networks(motherboard),
    to: MotherboardQueryOrigin

  @spec get_component_ids(Motherboard.t) ::
    [Component.id]
  defdelegate get_component_ids(motherboard),
    to: MotherboardQueryOrigin

  @spec get_hdds(Motherboard.t | Motherboard.id) ::
    [Component.HDD.t]
  defdelegate get_hdds(motherboard),
    to: MotherboardQueryOrigin

  @spec get_storages(Motherboard.t | Motherboard.id) ::
    [Storage.t]
  defdelegate get_storages(motherboard),
    to: MotherboardQueryOrigin

  defmodule Origin do

    alias Helix.Server.Model.Server
    alias Helix.Server.Query.Server, as: ServerQuery
    alias Helix.Software.Query.Storage, as: StorageQuery
    alias Helix.Hardware.Internal.Motherboard, as: MotherboardInternal
    alias Helix.Hardware.Query.Component, as: ComponentQuery

    defdelegate fetch(component),
      to: MotherboardInternal

    def fetch_by_server(server_id) do
      with \
        server = %Server{} <- ServerQuery.fetch(server_id),
        true <- not is_nil(server.motherboard_id),
        component = %{} <- ComponentQuery.fetch(server.motherboard_id)
      do
        fetch(component)
      else
        _ ->
          nil
      end
    end

    defdelegate fetch_by_nip(network_id, ip),
      to: MotherboardInternal

    defdelegate preload_components(motherboard),
      to: MotherboardInternal

    defdelegate get_slots(motherboard),
      to: MotherboardInternal

    defdelegate resources(motherboard),
      to: MotherboardInternal

    defdelegate get_networks(motherboard),
      to: MotherboardInternal

    defdelegate get_component_ids(motherboard),
      to: MotherboardInternal,
      as: :get_components_ids
      # Review: waiting opinion on pluralized objects

    defdelegate get_hdds(motherboard),
      to: MotherboardInternal

    def get_storages(motherboard) do
      motherboard
      |> get_hdds()
      |> Enum.map(&StorageQuery.fetch_by_hdd(&1.hdd_id))
    end
  end
end
