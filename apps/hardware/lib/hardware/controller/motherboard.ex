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
        acc.size + el.ram_size
      end)

    nic =
      cids
      |> Component.NIC.Query.from_component_ids()
      |> Component.NIC.Query.inner_join_network_connection()
      |> Repo.all()
      |> Enum.reduce(%{}, fn el, acc ->
        network = el.network_connection.network_id
        value = Map.take(el.network_connection, [:uplink, :downlink])

        Map.update(acc, network, value, &Map.merge(&1, value, fn _, v1, v2 -> v1 + v2 end))
      end)

    %{
      cpu: cpu,
      ram: ram,
      net: nic
    }
  end

  @spec find(HELL.PK.t) :: {:ok, Motherboard.t} | {:error, :notfound}
  def find(motherboard_id) do
    case Repo.get_by(Motherboard, motherboard_id: motherboard_id) do
      nil ->
        {:error, :notfound}
      res ->
        {:ok, res}
    end
  end

  @spec get_slots(Motherboard.t | HELL.PK.t) :: [MotherboardSlot.t]
  def get_slots(%Motherboard{motherboard_id: mid}),
    do: get_slots(mid)
  def get_slots(motherboard_id) do
    motherboard_id
    |> MotherboardSlot.Query.by_motherboard_id()
    |> Repo.all()
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