defmodule Helix.Hardware.Internal.Motherboard do

  alias Helix.Hardware.Model.Component
  alias Helix.Hardware.Model.ComponentSpec
  alias Helix.Hardware.Model.Motherboard
  alias Helix.Hardware.Model.MotherboardSlot
  alias Helix.Hardware.Repo

  @spec create_from_spec(ComponentSpec.t) ::
    {:ok, Motherboard.t}
    | {:error, Ecto.Changeset.t}
  def create_from_spec(component_spec) do
    component_spec
    |> Motherboard.create_from_spec()
    |> Repo.insert()
  end

  def get_components_ids(motherboard) do
    motherboard
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
  %{cpu: non_neg_integer,
    ram: non_neg_integer,
    hdd: non_neg_integer,
    net: %{any => %{uplink: non_neg_integer, downlink: non_neg_integer}}}
  def resources(motherboard) do
    components = get_components_ids(motherboard)

    cpu =
      components
      |> get_cpus_from_ids()
      |> Enum.reduce(0, fn el, acc ->
        acc + (el.cores * el.clock)
      end)

    ram =
      components
      |> get_rams_from_ids()
      |> Enum.reduce(0, fn el, acc ->
        acc + el.ram_size
      end)

    nic =
      components
      |> get_nics_from_ids()
      |> Enum.reduce(%{}, fn el, acc ->
        network = el.network_connection.network_id
        value = Map.take(el.network_connection, [:uplink, :downlink])

        sum_map_values = &Map.merge(&1, value, fn _, v1, v2 -> v1 + v2 end)

        Map.update(acc, network, value, sum_map_values)
      end)

    hdd =
      components
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

  @spec fetch!(Component.t) ::
    Motherboard.t
  def fetch!(component = %Component{component_type: :mobo}),
    do: Repo.get!(Motherboard, component.component_id)

  @spec get_slots(Motherboard.t | Motherboard.id) ::
    [MotherboardSlot.t]
  def get_slots(motherboard_or_motherboard_id) do
    motherboard_or_motherboard_id
    |> MotherboardSlot.Query.from_motherboard()
    |> Repo.all()
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
