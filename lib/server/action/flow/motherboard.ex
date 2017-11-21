defmodule Helix.Server.Action.Flow.Motherboard do

  import HELF.Flow

  alias HELL.IPv4
  alias HELL.Utils
  alias Helix.Entity.Action.Entity, as: EntityAction
  alias Helix.Network.Action.Network, as: NetworkAction
  alias Helix.Network.Query.Network, as: NetworkQuery
  alias Helix.Software.Action.Storage, as: StorageAction
  alias Helix.Software.Action.StorageDrive, as: StorageDriveAction
  alias Helix.Server.Action.Component, as: ComponentAction
  alias Helix.Server.Action.Motherboard, as: MotherboardAction
  alias Helix.Server.Model.Component
  alias Helix.Server.Query.Motherboard, as: MotherboardQuery

  @doc """
  Sets up the initial hardware for `entity`. Called right after an account is
  created.
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
        {:ok, motherboard} <- MotherboardAction.setup(mobo, slotted_components),
        on_fail(fn ->
          Enum.each(components, &MotherboardAction.unlink(motherboard, &1))
        end),

        # Link all components to the entity
        :ok <- link_components(components, entity),

        # Generate an IP and assign the basic ISP plan to the NIC
        {:ok, _nc, _nic} <- setup_networking(nic),

        # Creates the storage and attaches it to each HDD
        {:ok, _storage} <- setup_storage(hdd)
      do
        # Fetch mobo again because NIC and possibly other things have changed
        motherboard = MotherboardQuery.fetch(mobo.component_id)

        {:ok, motherboard}
      end
    end
  end

  defp map_components_slots(components) do
    Enum.map(components, fn component ->
      {component, Utils.concat_atom(component.type, :_0)}
    end)
  end

  defp link_components(components, entity) do
    Enum.reduce_while(components, :ok, fn component, acc ->
      case EntityAction.link_component(entity, component) do
        {:ok, _} ->
          on_fail(fn -> EntityAction.unlink_component(component) end)
          {:cont, :ok}

        _ ->
          {:halt, :error}
      end
    end)
  end

  # TODO: Use ISP abstraction instead of `Network.Connection`. #341
  defp setup_networking(nic = %Component{type: :nic}) do
    internet = NetworkQuery.internet()
    ip = IPv4.autogenerate()

    basic_plan = %{dlk: 128, ulk: 16}

    with \
      {:ok, nc} <- NetworkAction.Connection.create(internet, ip, nic),
      on_fail(fn -> NetworkAction.Connection.delete(nc) end),

      {:ok, new_nic} <-
        ComponentAction.NIC.update_transfer_speed(nic, basic_plan)
    do
      {:ok, nc, new_nic}
    end
  end

  defp setup_storage(hdd = %Component{type: :hdd}) do
    with \
      {:ok, storage} <- StorageAction.create(),
      # /\ First we create the storage
      on_fail(fn -> StorageAction.delete(storage) end),

      # And then we link it to the HDD
      :ok <- StorageDriveAction.link_drive(storage, hdd),
      on_fail(fn -> StorageDriveAction.unlink_drive(hdd) end)
    do
      {:ok, storage}
    end
  end
end
