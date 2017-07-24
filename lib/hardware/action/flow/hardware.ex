defmodule Helix.Hardware.Action.Flow.Hardware do

  import HELF.Flow

  alias Helix.Entity.Action.Entity, as: EntityAction
  alias Helix.Software.Action.Storage, as: StorageAction
  alias Helix.Software.Action.StorageDrive, as: StorageDriveAction
  alias Helix.Hardware.Action.Component, as: ComponentAction
  alias Helix.Hardware.Action.Motherboard, as: MotherboardAction
  alias Helix.Hardware.Model.Component.NIC
  alias Helix.Hardware.Model.NetworkConnection
  alias Helix.Hardware.Query.ComponentSpec, as: ComponentSpecQuery
  alias Helix.Hardware.Query.Motherboard, as: MotherboardQuery
  alias Helix.Hardware.Repo

  def player_initial_bundle do
    %{
      motherboard: ComponentSpecQuery.fetch("MOBO01"),
      components: [
        ComponentSpecQuery.fetch("CPU01"),
        ComponentSpecQuery.fetch("RAM01"),
        ComponentSpecQuery.fetch("HDD01"),
        ComponentSpecQuery.fetch("NIC01")
      ],
      network: %{
        network_id: "::",
        uplink: 100,
        downlink: 100
      }
    }
  end

  def setup_bundle(entity, bundle \\ player_initial_bundle()) do
    # TODO: Ecto.Multi to wrap this into one (two) transactions instead of
    #   several failable operations
    build_components = fn ->
      Enum.reduce_while(bundle.components, {:ok, []}, fn spec, {:ok, acc} ->
        with \
          {:ok, component} <- ComponentAction.create_from_spec(spec),
          on_fail(fn -> ComponentAction.delete(component) end),

          {:ok, _} <- EntityAction.link_component(
            entity,
            component.component_id)
        do
          {:cont, {:ok, [component| acc]}}
        end
      end)
    end

    # This will be improved with a MotherboardAPI that simply receives a
    # collection of components and try to link them all
    link_components = fn motherboard, components ->
      motherboard = MotherboardQuery.fetch!(motherboard)
      slots = MotherboardQuery.get_slots(motherboard)
      slots = Enum.group_by(slots, &(&1.link_component_type))

      components = Enum.group_by(components, &(&1.component_type))

      link_strategy =
        slots
        |> Map.merge(components, fn _, v1, v2 -> Enum.zip(v1, v2) end)
        |> Map.values()
        |> List.flatten()

      Enum.reduce_while(link_strategy, :ok, fn {slot, component}, :ok ->
        case MotherboardAction.link(slot, component) do
          {:ok, slot} ->
            on_fail(fn -> MotherboardAction.unlink(slot) end)
            {:cont, :ok}
          _ ->
            {:halt, :error}
        end
      end)
    end

    flowing do
      with \
        {:ok, motherboard} <- ComponentAction.create_from_spec(
          bundle.motherboard),
        on_fail(fn -> ComponentAction.delete(motherboard) end),

        {:ok, _} <- EntityAction.link_component(
          entity,
          motherboard.component_id),
        on_fail(fn ->
          EntityAction.unlink_component(motherboard.component_id)
        end),

        {:ok, components} <- build_components.(),

        :ok <- link_components.(motherboard, components),

        # This is extremely ugly and will be fixed by providing an API for
        # NetworkConnection
        changeset = NetworkConnection.create_changeset(bundle.network),
        {:ok, net} <- Repo.insert(changeset),
        on_fail(fn -> Repo.delete(net) end),

        hdd = %{} <- Enum.find(components, &(&1.component_type == :hdd)),
        {:ok, storage} <- StorageAction.create(),
        on_fail(fn -> StorageAction.delete(storage.storage_id) end),
        :ok <- StorageDriveAction.link_drive(storage, hdd.component_id),
        on_fail(fn -> StorageDriveAction.unlink_drive(hdd.component_id) end),

        nic = %{} <- Enum.find(components, &(&1.component_type == :nic)),
        nic = Repo.get(NIC, nic.component_id),
        nic_params = %{network_connection_id: net.network_connection_id},
        cs = NIC.update_changeset(nic, nic_params),
        {:ok, _} <- Repo.update(cs)
      do
        # This is because `motherboard` is actually a component
        %{motherboard_id: id} = MotherboardQuery.fetch!(motherboard)
        {:ok, id}
      end
    end
  end
end
