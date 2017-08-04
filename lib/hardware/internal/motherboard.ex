defmodule Helix.Hardware.Internal.Motherboard do

  alias Helix.Cache.Action.Cache, as: CacheAction
  alias Helix.Network.Model.Network
  alias Helix.Hardware.Model.Component
  alias Helix.Hardware.Model.Component.NIC
  alias Helix.Hardware.Model.ComponentSpec
  alias Helix.Hardware.Model.Motherboard
  alias Helix.Hardware.Model.MotherboardSlot
  alias Helix.Hardware.Model.NetworkConnection
  alias Helix.Hardware.Internal.Component, as: ComponentInternal
  alias Helix.Hardware.Internal.NetworkConnection, as: NetworkConnectionInternal
  alias Helix.Hardware.Repo

  @spec fetch(Component.idt) ::
    Motherboard.t
    | nil
  def fetch(id),
    do: Repo.get(Motherboard, id)

  @spec fetch_by_slot(MotherboardSlot.t | MotherboardSlot.id) ::
    Motherboard.t
    | nil
  def fetch_by_slot(slot = %MotherboardSlot{}) do
    slot
    |> Repo.preload(:motherboard)
    |> Map.get(:motherboard)
  end
  def fetch_by_slot(slot_id) do
    case Repo.get(MotherboardSlot, slot_id) do
      nil ->
        nil
      slot ->
        fetch_by_slot(slot)
    end
  end

  @spec fetch_by_nip(Network.id, NetworkConnection.ip) ::
    Motherboard.t
    | nil
  def fetch_by_nip(network_id, ip) do
    with \
      nc = %{} <- NetworkConnectionInternal.fetch_by_nip(network_id, ip),
      nic = %{} <- NetworkConnectionInternal.get_nic(nc),
      slot = %{} <- ComponentInternal.get_motherboard_slot(nic)
    do
      fetch_by_slot(slot)
    else
      _ ->
        nil
    end
  end

  @spec preload_components(Motherboard.t) ::
    Motherboard.t
  def preload_components(motherboard),
    do: Repo.preload(motherboard, slots: :component)

  @spec get_networks(Motherboard.t | Component.idt) ::
    [NetworkConnection.t]
  def get_networks(motherboard) do
    with \
      slots = [_|_] <- get_slots(motherboard),
      nics = [_|_] <- Enum.filter(slots, &(&1.link_component_type == :nic)),
      nics = [_|_] <- Enum.reject(nics, &is_nil(&1.link_component_id)),
      nics = [_|_] <- Enum.map(nics, &Repo.get(NIC, &1.link_component_id)),
      nics = [_|_] <- Enum.reject(nics, &is_nil(&1.network_connection_id)),
      networks = [_|_] <- Enum.map(
        nics,
        &Repo.get(NetworkConnection, &1.network_connection_id))
    do
      networks
    end
  end

  @spec get_components_ids(Motherboard.t | Component.idt) ::
    [Component.id]
  def get_components_ids(motherboard) do
    motherboard
    |> MotherboardSlot.Query.by_motherboard()
    |> MotherboardSlot.Query.only_linked_slots()
    |> MotherboardSlot.Query.select_component_id()
    |> Repo.all()
  end

  def get_cpus(motherboard) do
    motherboard
    |> get_components_ids()
    |> get_cpus_from_ids()
  end

  def get_rams(motherboard) do
    motherboard
    |> get_components_ids()
    |> get_rams_from_ids()
  end

  def get_nics(motherboard) do
    motherboard
    |> get_components_ids()
    |> get_nics_from_ids()
  end

  def get_hdds(motherboard) do
    motherboard
    |> get_components_ids()
    |> get_hdds_from_ids()
  end

  defp get_cpus_from_ids(components) do
    components
    |> Component.CPU.Query.from_components_ids()
    |> Repo.all()
  end

  defp get_rams_from_ids(components) do
    components
    |> Component.RAM.Query.from_components_ids()
    |> Repo.all()
  end

  defp get_nics_from_ids(components) do
    components
    |> Component.NIC.Query.from_components_ids()
    |> Component.NIC.Query.inner_join_network_connection()
    |> Repo.all()
  end

  defp get_hdds_from_ids(components) do
    components
    |> Component.HDD.Query.from_components_ids()
    |> Repo.all()
  end

  @spec resources(Motherboard.t) ::
    %{
      cpu: non_neg_integer,
      ram: non_neg_integer,
      hdd: non_neg_integer,
      net: %{String.t => %{uplink: non_neg_integer, downlink: non_neg_integer}}
    }
  def resources(motherboard) do
    components_ids = get_components_ids(motherboard)

    cpu =
      components_ids
      |> get_cpus_from_ids()
      |> Enum.reduce(0, fn el, acc ->
        acc + (el.cores * el.clock)
      end)

    ram =
      components_ids
      |> get_rams_from_ids()
      |> Enum.reduce(0, fn el, acc ->
        acc + el.ram_size
      end)

    nic =
      components_ids
      |> get_nics_from_ids()
      |> Enum.reduce(%{}, fn el, acc ->
        network = to_string(el.network_connection.network_id)
        value = Map.take(el.network_connection, [:uplink, :downlink])

        sum_map_values = &Map.merge(&1, value, fn _, v1, v2 -> v1 + v2 end)

        Map.update(acc, network, value, sum_map_values)
      end)

    hdd =
      components_ids
      |> get_hdds_from_ids()
      |> Enum.reduce(0, fn el, acc ->
        acc + el.hdd_size
      end)

    %{
      cpu: cpu,
      ram: ram,
      hdd: hdd,
      net: nic
    }
  end

  @spec get_slots(Motherboard.t | Component.idt) ::
    [MotherboardSlot.t]
  def get_slots(motherboard) do
    motherboard
    |> MotherboardSlot.Query.by_motherboard()
    |> Repo.all()
  end

  @spec create_from_spec(ComponentSpec.t) ::
    {:ok, Motherboard.t}
    | {:error, Ecto.Changeset.t}
  def create_from_spec(component_spec) do
    component_spec
    |> Motherboard.create_from_spec()
    |> Repo.insert()
  end

  @spec link(MotherboardSlot.t, Component.idt) ::
    {:ok, MotherboardSlot.t}
    | {:error, Ecto.Changeset.t}
  def link(slot, component) do
    params = %{link_component_id: component}
    changeset = MotherboardSlot.update_changeset(slot, params)

    with result = {:ok, _} <- Repo.update(changeset) do
      CacheAction.update_component(component)
      CacheAction.update_component(slot.motherboard_id)

      result
    end
  end

  @spec unlink(MotherboardSlot.t) ::
    {:ok, MotherboardSlot.t}
    | {:error, Ecto.Changeset.t}
  def unlink(slot) do
    params = %{link_component_id: nil}
    changeset = MotherboardSlot.update_changeset(slot, params)

    with result = {:ok, _} <- Repo.update(changeset) do
      CacheAction.purge_component(slot.link_component_id)
      CacheAction.update_component(slot.motherboard_id)

      result
    end
  end

  @spec unlink_components_from_motherboard(Motherboard.t | Component.idt) ::
    :ok
  def unlink_components_from_motherboard(motherboard) do
    components = get_components_ids(motherboard)

    motherboard
    |> MotherboardSlot.Query.by_motherboard()
    |> Repo.update_all(set: [link_component_id: nil])

    CacheAction.update_component(motherboard)
    Enum.map(components, &CacheAction.purge_component(&1))

    :ok
  end

  @spec delete(Motherboard.t) ::
    :ok
  # FIXME: this function should not exist. To delete a motherboard, just like
  #   any other component, the Component record should be deleted (and along
  #   with it, check if it is a motherboard to execute the proper cache update
  #   method)
  def delete(motherboard) do
    Repo.delete(motherboard)

    CacheAction.purge_component(motherboard)
    CacheAction.update_server_by_motherboard(motherboard)

    :ok
  end
end
