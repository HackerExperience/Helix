defmodule Helix.Hardware.Controller.Motherboard do

  alias Helix.Hardware.Model.Component
  alias Helix.Hardware.Model.ComponentSpec
  alias Helix.Hardware.Model.Motherboard
  alias Helix.Hardware.Model.MotherboardSlot
  alias Helix.Hardware.Repo

  @spec create_from_spec(ComponentSpec.t) :: {:ok, Motherboard.t} | {:error, Ecto.Changeset.t}
  def create_from_spec(component_spec) do
    component_spec
    |> Motherboard.create_from_spec()
    |> Repo.insert()
  end

  # REVIEW: refactor this
  @spec resources(Motherboard.t) :: %{cpu: non_neg_integer, ram: non_neg_integer, net: %{any => %{uplink: non_neg_integer, downlink: non_neg_integer}}}
  def resources(motherboard) do
    cids =
      motherboard
      |> MotherboardSlot.Query.from_motherboard()
      |> MotherboardSlot.Query.only_linked_slots()
      |> MotherboardSlot.Query.select_component_id()
      |> Repo.all()

    cpu =
      cids
      |> Component.CPU.Query.from_component_ids()
      |> Repo.all()
      |> Enum.reduce(0, fn el, acc ->
        # REVIEW: Move the operation (cores * clock) to the CPU model ?
        acc + (el.cores * el.clock)
      end)

    ram =
      cids
      |> Component.RAM.Query.from_component_ids()
      |> Repo.all()
      |> Enum.reduce(0, fn el, acc ->
        acc + el.ram_size
      end)

    nic =
      cids
      |> Component.NIC.Query.from_component_ids()
      |> Component.NIC.Query.inner_join_network_connection()
      |> Repo.all()
      |> Enum.reduce(%{}, fn el, acc ->
        network = el.network_connection.network_id
        value = Map.take(el.network_connection, [:uplink, :downlink])

        sum_map_values = &Map.merge(&1, value, fn _, v1, v2 -> v1 + v2 end)

        Map.update(acc, network, value, sum_map_values)
      end)

    %{
      cpu: cpu,
      ram: ram,
      net: nic
    }
  end

  @spec fetch!(Component.t) :: Motherboard.t
  def fetch!(component = %Component{component_type: :mobo}),
    do: Repo.get!(Motherboard, component.component_id)

  @spec get_slots(Motherboard.t | HELL.PK.t) :: [MotherboardSlot.t]
  def get_slots(motherboard_or_motherboard_id) do
    motherboard_or_motherboard_id
    |> MotherboardSlot.Query.from_motherboard()
    |> Repo.all()
  end

  @spec unlink_components_from_motherboard(Motherboard.t | HELL.PK.t) :: :ok
  def unlink_components_from_motherboard(motherboard_or_motherboard_id) do
    motherboard_or_motherboard_id
    |> MotherboardSlot.Query.from_motherboard()
    |> Repo.update_all(set: [link_component_id: nil])

    :ok
  end

  @spec delete(Motherboard.t | HELL.PK.t) :: no_return
  def delete(%Motherboard{motherboard_id: mid}),
    do: delete(mid)
  def delete(motherboard_id) do
    motherboard_id
    |> Motherboard.Query.by_id()
    |> Repo.delete_all()

    :ok
  end
end
