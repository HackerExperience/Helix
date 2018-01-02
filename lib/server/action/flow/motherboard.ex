defmodule Helix.Server.Action.Flow.Motherboard do

  import HELF.Flow

  alias HELL.IPv4
  alias HELL.Utils
  alias Helix.Event
  alias Helix.Entity.Action.Entity, as: EntityAction
  alias Helix.Entity.Model.Entity
  alias Helix.Network.Action.Network, as: NetworkAction
  alias Helix.Network.Model.Network
  alias Helix.Network.Query.Network, as: NetworkQuery
  alias Helix.Software.Action.Storage, as: StorageAction
  alias Helix.Software.Action.StorageDrive, as: StorageDriveAction
  alias Helix.Software.Model.Storage
  alias Helix.Server.Action.Component, as: ComponentAction
  alias Helix.Server.Action.Motherboard, as: MotherboardAction
  alias Helix.Server.Model.Component
  alias Helix.Server.Model.Motherboard
  alias Helix.Server.Query.Motherboard, as: MotherboardQuery

  @spec initial_hardware(Entity.t, Event.relay) ::
    {:ok, Motherboard.t, Component.mobo}
  @doc """
  Sets up the initial hardware for `entity`. Called right after an entity is
  created.

  It:
  - Creates all initial components (HDD, RAM, NIC, CPU, Mobo)
  - Links them to the Motherboard
  - Links them to the Entity
  - Creates the initial storage to be used by HDD
  - Creates the initial NetworkConnection to be used by NIC
  """
  def initial_hardware(entity, _relay) do
    flowing do
      with \
        {:ok, components} <-
          ComponentAction.create_initial_components(),
        on_fail(fn -> Enum.each(components, &ComponentAction.delete/1) end),

        # Insert the default slot_id for each component
        slotted_components = map_components_slots(components),

        # Get the mobo, nic and hdd, which need some extra operations
        mobo = Enum.find(components, &(&1.type == :mobo)),
        nic = Enum.find(components, &(&1.type == :nic)),
        hdd = Enum.find(components, &(&1.type == :hdd)),

        # Link all components into the motherboard
        {:ok, _} <- MotherboardAction.setup(mobo, slotted_components),
        on_fail(fn -> Enum.each(components, &MotherboardAction.unlink(&1)) end),

        # Link all components to the entity
        :ok <- link_components(components, entity),

        # Creates the storage and attaches it to each HDD
        {:ok, _storage} <- setup_storage(hdd)
      do
        # Fetch mobo again because NIC and possibly other things have changed
        motherboard = MotherboardQuery.fetch(mobo.component_id)

        {:ok, motherboard, mobo}
      end
    end
  end

  # TODO: Use ISP abstraction instead of `Network.Connection`. #341
  def isp_connect(entity, motherboard = %Motherboard{}) do
    [nic] = MotherboardQuery.get_nics(motherboard)

    isp_connect(entity, nic)
  end

  def isp_connect(entity, nic = %Component{type: :nic}) do
    internet = NetworkQuery.internet()
    ip = IPv4.autogenerate()
    basic_plan = %{dlk: 128, ulk: 16}

    setup_network(entity, nic, internet, ip, basic_plan)
  end

  def setup_network(
    entity = %Entity{},
    nic = %Component{type: :nic},
    network = %Network{},
    ip,
    speed = %{dlk: _, ulk: _})
  do
    flowing do
      with \
        {:ok, nc} <- NetworkAction.Connection.create(network, ip, entity, nic),
        on_fail(fn -> NetworkAction.Connection.delete(nc) end),

        {:ok, new_nic} <- ComponentAction.NIC.update_transfer_speed(nic, speed),
        {:ok, new_nic} <-
          ComponentAction.NIC.update_network(new_nic, network.network_id)
      do
        {:ok, nc, new_nic}
      end
    end
  end

  def setup_network(
    entity = %Entity{},
    nic = %Component{type: :nic},
    nc = %Network.Connection{nic_id: nil},
    speed = %{dlk: _, ulk: _})
  do
    flowing do
      with \
        {:ok, nc} = NetworkAction.Connection.update_nic(nc, nic),
        on_fail(fn -> NetworkAction.Connection.update_nic(nc, nil) end),

        {:ok, new_nic} <- ComponentAction.NIC.update_transfer_speed(nic, speed),
        {:ok, new_nic} <-
          ComponentAction.NIC.update_network(new_nic, nc.network_id)
      do
        {:ok, nc, new_nic}
      end
    end
  end

  @spec map_components_slots([Component.t]) ::
    [Motherboard.slot]
  defp map_components_slots(components) do
    Enum.map(components, fn component ->
      {component, Utils.concat_atom(component.type, :_1)}
    end)
  end

  @spec link_components([Component.t], Entity.t) ::
    :ok
    | :error
  defp link_components(components, entity) do
    Enum.reduce_while(components, :ok, fn component, _ ->
      case EntityAction.link_component(entity, component) do
        {:ok, _} ->
          on_fail(fn -> EntityAction.unlink_component(component) end)
          {:cont, :ok}

        _ ->
          {:halt, :error}
      end
    end)
  end

  @spec setup_storage(Component.hdd) ::
   {:ok, Storage.t}
  defp setup_storage(hdd = %Component{type: :hdd}) do
    with \
      {:ok, storage} <- StorageAction.create(),
      # /\ First we create the storage
      on_fail(fn -> StorageAction.delete(storage) end),

      # And then we link it to the HDD
      :ok <- StorageDriveAction.link_drive(storage, hdd.component_id),
      on_fail(fn -> StorageDriveAction.unlink_drive(hdd.component_id) end)
    do
      {:ok, storage}
    end
  end
end
