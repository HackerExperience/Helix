defmodule Helix.Account.Service.Flow.Account do

  # alias Helix.Event
  alias Helix.Entity.Service.API.Entity, as: EntityAPI
  alias Helix.Hardware.Model.NetworkConnection
  alias Helix.Hardware.Model.Component.NIC
  alias Helix.Hardware.Repo, as: HardwareRepo
  alias Helix.Hardware.Service.API.Component, as: ComponentAPI
  alias Helix.Hardware.Service.API.ComponentSpec, as: ComponentSpecAPI
  alias Helix.Hardware.Service.API.Motherboard, as: MotherboardAPI
  alias Helix.Server.Service.API.Server, as: ServerAPI
  alias Helix.Software.Controller.Storage
  alias Helix.Software.Controller.StorageDrive
  alias Helix.Account.Model.Account
  alias Helix.Account.Service.API.Account, as: API

  import HELF.Flow

  @spec setup_account(HELL.PK.t | Account.t) ::
    {:ok, %{entity: struct, server: struct}}
    | :error
  @doc """
  Setups the input account

  Does so by creating an entity, a server, basic components and linking
  everything together.
  """
  def setup_account(account_id) when is_binary(account_id),
    do: setup_account(API.fetch(account_id))
  def setup_account(account) do
    # email = account.email

    flowing do
      with \
        {:ok, entity} <- EntityAPI.create_from_specialization(account),
        on_fail(fn -> EntityAPI.delete(entity) end),

        {:ok, motherboard_id} <- setup_component_bundle(entity),

        {:ok, server} <- setup_server(entity, motherboard_id)
      do
        {:ok, %{entity: entity, server: server}}
      else
        _ ->
          :error
      end
    end
  end

  defp setup_server(entity, motherboard_id) do
    flowing do
      with \
        {:ok, server} <- ServerAPI.create(:desktop),
        on_fail(fn -> ServerAPI.delete(server) end),

        {:ok, server} <- ServerAPI.attach(server, motherboard_id),
        on_fail(fn -> ServerAPI.detach(server) end),

        server_id = server.server_id,
        {:ok, _} <- EntityAPI.link_server(entity, server_id),
        on_fail(fn -> EntityAPI.unlink_server(server_id) end)
      do
        {:ok, server}
      end
    end
  end

  defp setup_component_bundle(entity) do
    bundle = %{
      motherboard: ComponentSpecAPI.fetch("MOBO01"),
      components: [
        ComponentSpecAPI.fetch("CPU01"),
        ComponentSpecAPI.fetch("RAM01"),
        ComponentSpecAPI.fetch("HDD01"),
        ComponentSpecAPI.fetch("NIC01")
      ],
      network: %{
        network_id: "::",
        uplink: 100,
        downlink: 100
      }
    }

    # TODO: Ecto.Multi to wrap this into one (two) transactions instead of
    #   several failable operations
    build_components = fn ->
      Enum.reduce_while(bundle.components, {:ok, []}, fn spec, {:ok, acc} ->
        with \
          {:ok, component} <- ComponentAPI.create_from_spec(spec),
          on_fail(fn -> ComponentAPI.delete(component) end),

          {:ok, _} <- EntityAPI.link_component(entity, component.component_id)
        do
          {:cont, {:ok, [component| acc]}}
        end
      end)
    end

    # This will be improved with a MotherboardAPI that simply receives a
    # collection of components and try to link them all
    link_components = fn motherboard, components ->
      motherboard = MotherboardAPI.fetch!(motherboard)
      slots = MotherboardAPI.get_slots(motherboard)
      slots = Enum.group_by(slots, &(&1.link_component_type))

      components = Enum.group_by(components, &(&1.component_type))

      link_strategy =
        slots
        |> Map.merge(components, fn _, v1, v2 -> Enum.zip(v1, v2) end)
        |> Map.values()
        |> List.flatten()

      Enum.reduce_while(link_strategy, :ok, fn {slot, component}, :ok ->
        case MotherboardAPI.link(slot, component) do
          {:ok, slot} ->
            on_fail(fn -> MotherboardAPI.unlink(slot) end)
            {:cont, :ok}
          _ ->
            {:halt, :error}
        end
      end)
    end

    flowing do
      with \
        {:ok, motherboard} <- ComponentAPI.create_from_spec(bundle.motherboard),
        on_fail(fn -> ComponentAPI.delete(motherboard) end),

        {:ok, _} <- EntityAPI.link_component(entity, motherboard.component_id),
        on_fail(fn -> EntityAPI.unlink_component(motherboard.component_id) end),

        {:ok, components} <- build_components.(),

        :ok <- link_components.(motherboard, components),

        # This is extremely ugly and will be fixed by providing an API for
        # NetworkConnection
        changeset = NetworkConnection.create_changeset(bundle.network),
        {:ok, net} <- HardwareRepo.insert(changeset),
        on_fail(fn -> HardwareRepo.delete(net) end),

        hdd = %{} <- Enum.find(components, &(&1.component_type == :hdd)),
        {:ok, storage} <- Storage.create(),
        on_fail(fn -> Storage.delete(storage.storage_id) end),
        :ok <- StorageDrive.link_drive(storage, hdd.component_id),
        on_fail(fn -> StorageDrive.unlink_drive(hdd.component_id) end),

        nic = %{} <- Enum.find(components, &(&1.component_type == :nic)),
        nic = HardwareRepo.get(NIC, nic.component_id),
        nic_params = %{network_connection_id: net.network_connection_id},
        cs = NIC.update_changeset(nic, nic_params),
        {:ok, _} <- HardwareRepo.update(cs)
      do
        # This is because `motherboard` is actually a component
        %{motherboard_id: id} = MotherboardAPI.fetch!(motherboard)
        {:ok, id}
      end
    end
  end
end
