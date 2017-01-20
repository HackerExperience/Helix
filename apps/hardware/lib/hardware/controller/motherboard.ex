defmodule Helix.Hardware.Controller.Motherboard do

  alias Helix.Hardware.Model.Component
  alias Helix.Hardware.Model.Motherboard
  alias Helix.Hardware.Model.MotherboardSlot
  alias Helix.Hardware.Repo

  @spec create(Motherboard.creation_params) :: {:ok, Motherboard.t} | no_return
  def create(params) do
    Repo.transaction fn ->
      motherboard = Motherboard.create_changeset(params)

      case Repo.insert(motherboard) do
        {:ok, mb} ->
          mb
        _ ->
          # TODO: Proper error message
          Repo.rollback(:internal_error)
      end
    end
  end

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

  @spec get_slots(HELL.PK.t) :: [MotherboardSlot.t]
  def get_slots(motherboard_id) do
    motherboard_id
    |> MotherboardSlot.Query.by_motherboard_id()
    |> Repo.all()
  end

  @spec delete(HELL.PK.t) :: no_return
  def delete(motherboard_id) do
    {status, _} = Repo.transaction fn ->
      motherboard_id
      |> Motherboard.Query.by_id()
      |> Repo.delete_all()
    end

    status
  end
end