defmodule Helix.Hardware.Internal.Motherboard do

  alias Helix.Network.Model.Network
  alias Helix.Hardware.Model.Component
  alias Helix.Hardware.Model.Component.NIC
  alias Helix.Hardware.Model.ComponentSpec
  alias Helix.Hardware.Model.Motherboard
  alias Helix.Hardware.Model.MotherboardSlot
  alias Helix.Hardware.Model.NetworkConnection
  alias Helix.Hardware.Repo

  @spec fetch(Component.t | Motherboard.id) ::
    Motherboard.t
    | nil
  def fetch(component = %Component{component_type: :mobo}),
    do: fetch(component.component_id)
  def fetch(component = %Component{component_type: _}),
    do: nil
  def fetch(motherboard_id) do
    motherboard_id
    |> Motherboard.Query.by_id()
    |> Repo.one()
  end

  @spec fetch_by_nip(Network.id, NetworkConnection.ip) ::
    Motherboard.t
    | nil
  def fetch_by_nip(network_id, ip) do
    query = [network_id: network_id, ip: ip]

    with \
      net = %{} <- Repo.get_by(NetworkConnection, query),
      nic = %{} <- net |> Repo.preload(:nic) |> Map.fetch!(:nic),
      slot = %{} <- Repo.get_by(MotherboardSlot, link_component_id: nic.nic_id)
    do
      slot
      |> Repo.preload(:motherboard)
      |> Map.get(:motherboard)
    else
      _ ->
        nil
    end
  end

  @spec preload_components(Motherboard.t) ::
    Motherboard.t
  def preload_components(motherboard),
    do: Repo.preload(motherboard, slots: :component)

  @spec get_networks(Motherboard.t | Motherboard.id) ::
    [NetworkConnection.t]
  def get_networks(motherboard) do
    with \
      slots = [_|_] <- get_slots(motherboard),
      nics = [_|_] <- Enum.filter(slots, &(&1.link_component_type == :nic)),
      nics = [_|_] <- Enum.reject(nics, &is_nil(&1.link_component_id)),
      nics = [_|_] <- Enum.map(nics, &Repo.get(NIC, &1.link_component_id)),
      networks = [_|_] <- Enum.map(
        nics,
        &Repo.get(NetworkConnection, &1.network_connection_id))
    do
      networks
    end
  end

  @spec get_components_ids(Motherboard.t | Motherboard.id) ::
    [Component.id]
  def get_components_ids(motherboard) do
    motherboard
    # |> preload_components()
    |> MotherboardSlot.Query.from_motherboard()
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
    |> Component.CPU.Query.from_component_ids()
    |> Repo.all()
  end

  defp get_rams_from_ids(components) do
    components
    |> Component.RAM.Query.from_component_ids()
    |> Repo.all()
  end

  defp get_nics_from_ids(components) do
    components
    |> Component.NIC.Query.from_component_ids()
    |> Component.NIC.Query.inner_join_network_connection()
    |> Repo.all()
  end

  defp get_hdds_from_ids(components) do
    components
    |> Component.HDD.Query.from_component_ids()
    |> Repo.all()
  end

  @spec resources(Motherboard.t) ::
    %{
      cpu: non_neg_integer,
      ram: non_neg_integer,
      hdd: non_neg_integer,
      net: %{
        Network.id =>
          %{
            uplink: non_neg_integer,
            downlink: non_neg_integer
          }
          | %{}
      }
    }
  def resources(motherboard) do
    component_ids = get_components_ids(motherboard)

    cpu =
      component_ids
      |> get_cpus_from_ids()
      |> Enum.reduce(0, fn el, acc ->
        acc + (el.cores * el.clock)
      end)

    ram =
      component_ids
      |> get_rams_from_ids()
      |> Enum.reduce(0, fn el, acc ->
        acc + el.ram_size
      end)

    nic =
      component_ids
      |> get_nics_from_ids()
      |> Enum.reduce(%{}, fn el, acc ->
        network = el.network_connection.network_id
        value = Map.take(el.network_connection, [:uplink, :downlink])

        sum_map_values = &Map.merge(&1, value, fn _, v1, v2 -> v1 + v2 end)

        Map.update(acc, network, value, sum_map_values)
      end)

    hdd =
      component_ids
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

  @spec get_slots(Motherboard.t | Motherboard.id) ::
    [MotherboardSlot.t]
  def get_slots(motherboard_or_motherboard_id) do
    motherboard_or_motherboard_id
    |> MotherboardSlot.Query.from_motherboard()
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

  @spec link(MotherboardSlot.t, Component.t) ::
    {:ok, MotherboardSlot.t}
    | {:error, Ecto.Changeset.t}
  def link(slot, component) do
    params = %{link_component_id: component.component_id}

    slot
    |> MotherboardSlot.update_changeset(params)
    |> Repo.update()
  end

  @spec unlink(MotherboardSlot.t) ::
    {:ok, MotherboardSlot.t}
  def unlink(slot) do
    slot
    |> MotherboardSlot.update_changeset(%{link_component_id: nil})
    |> Repo.update()
  end

  @spec unlink_components_from_motherboard(Motherboard.t | Motherboard.id) ::
    :ok
  def unlink_components_from_motherboard(motherboard_or_motherboard_id) do
    motherboard_or_motherboard_id
    |> MotherboardSlot.Query.from_motherboard()
    |> Repo.update_all(set: [link_component_id: nil])

    :ok
  end

  @spec delete(Motherboard.t | Motherboard.id) ::
    :ok
  def delete(%Motherboard{motherboard_id: mid}),
    do: delete(mid)
  def delete(motherboard_id) do
    motherboard_id
    |> Motherboard.Query.by_id()
    |> Repo.delete_all()

    :ok
  end
end
