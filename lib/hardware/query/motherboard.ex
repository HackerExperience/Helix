defmodule Helix.Hardware.Query.Motherboard do

  alias Helix.Hardware.Model.Component
  alias Helix.Hardware.Model.Motherboard
  alias Helix.Hardware.Model.MotherboardSlot
  alias Helix.Hardware.Query.Motherboard.Origin, as: MotherboardQueryOrigin

  @spec fetch!(Component.t) ::
    Motherboard.t
  @doc """
  Fetches a motherboard by component
  """
  defdelegate fetch!(component),
    to: MotherboardQueryOrigin

  @spec fetch_by_server(HELL.PK.t) :: Motherboard.t | nil
  defdelegate fetch_by_server(server_id),
    to: MotherboardQueryOrigin

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
    %{cpu: non_neg_integer,
      hdd: non_neg_integer,
      ram: non_neg_integer,
      net: %{any => %{uplink: non_neg_integer, downlink: non_neg_integer}}}
  defdelegate resources(motherboard),
    to: MotherboardQueryOrigin

  defdelegate get_networks(motherboard),
    to: MotherboardQueryOrigin

  defdelegate get_components(motherboard),
    to: MotherboardQueryOrigin

  defdelegate get_hdds(motherboard),
    to: MotherboardQueryOrigin

  defdelegate get_storages(motherboard),
    to: MotherboardQueryOrigin


  defmodule Origin do

    alias Helix.Server.Model.Server
    alias Helix.Server.Query.Server, as: ServerQuery
    alias Helix.Software.Query.Storage, as: StorageQuery
    alias Helix.Hardware.Internal.Motherboard, as: MotherboardInternal
    alias Helix.Hardware.Model.NetworkConnection
    alias Helix.Hardware.Repo
    alias Helix.Hardware.Query.Component, as: ComponentQuery
    alias Helix.Hardware.Model.Component.NIC

    def fetch!(component) do
      MotherboardInternal.fetch!(component)
    end

    def fetch_by_server(server_id) do
      with \
        server = %Server{} <- ServerQuery.fetch(server_id),
        true <- not is_nil(server.motherboard_id),
        component = %{} <- ComponentQuery.fetch(server.motherboard_id),
        motherboard = %{} <- fetch!(component)
      do
        motherboard
      else
        _ ->
          :nil
      end
    end

    def fetch_by_nip(network_id, ip) do
      # TODO: Query using its own Internal
      alias Helix.Hardware.Model.NetworkConnection
      query = [network_id: network_id, ip: ip]

      with \
        net = %{} <- Repo.get_by(NetworkConnection, query),
        nic = %{} <- net |> Repo.preload(:nic) |> Map.fetch!(:nic),
        slot = %{} <- Repo.get_by(MotherboardSlot, link_component_id: nic.nic_id)
      do
        slot.motherboard_id
      else
        _ ->
          nil
      end
    end

    def get_slots(motherboard) do
      MotherboardInternal.get_slots(motherboard)
    end

    # FIXME: Does not belong here
    def preload_components(motherboard) do
      Repo.preload(motherboard, slots: :component)
    end

    def resources(motherboard) do
      MotherboardInternal.resources(motherboard)
    end

    def get_networks(motherboard) do
      with \
        slots = [_|_] <- get_slots(motherboard),
        nics = [_|_] <- Enum.filter(slots, &(&1.link_component_type == :nic)),
        nics = [_|_] <- Enum.reject(nics, &is_nil(&1.link_component_id)),
        nics = [_|_] <- Enum.map(nics, &Repo.get(NIC, &1.link_component_id)),
        nets = [_|_] <- Enum.map(
          nics,
          &Repo.get(NetworkConnection, &1.network_connection_id))
      do
        nets
      end
    end

    def get_components(motherboard) do
      motherboard
      |> preload_components()
      |> MotherboardInternal.get_components_ids()
    end

    def get_hdds(motherboard) do
      motherboard
      |> MotherboardInternal.get_hdds()
    end

    def get_storages(motherboard) do
      # FIXME: Works only for one hd
      motherboard
      |> get_hdds()
      |> List.first()
      |> Map.get(:hdd_id)
      |> StorageQuery.fetch_by_hdd()
    end

  end
end
