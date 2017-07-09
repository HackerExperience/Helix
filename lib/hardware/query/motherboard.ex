defmodule Helix.Hardware.Query.Motherboard do

  alias Helix.Hardware.Internal.Motherboard, as: MotherboardInternal
  alias Helix.Hardware.Model.Component
  alias Helix.Hardware.Model.Motherboard
  alias Helix.Hardware.Model.MotherboardSlot
  alias Helix.Hardware.Repo

  @spec fetch!(Component.t) :: Motherboard.t
  @doc """
  Fetches a motherboard by component
  """
  def fetch!(component) do
    MotherboardInternal.fetch!(component)
  end

  @spec get_slots(Motherboard.t | HELL.PK.t) :: [MotherboardSlot.t]
  @doc """
  Gets every slot from a motherboard
  """
  def get_slots(motherboard) do
    MotherboardInternal.get_slots(motherboard)
  end

  @spec preload_components(Motherboard.t) :: Motherboard.t
  def preload_components(motherboard) do
    Repo.preload(motherboard, slots: :component)
  end

  @spec resources(Motherboard.t) :: %{cpu: non_neg_integer, ram: non_neg_integer, net: %{any => %{uplink: non_neg_integer, downlink: non_neg_integer}}}
  def resources(motherboard) do
    MotherboardInternal.resources(motherboard)
  end

end
