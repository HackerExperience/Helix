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
  defdelegate fetch!(component),
    to: MotherboardInternal

  @spec get_slots(Motherboard.t | Motherboard.id) ::
    [MotherboardSlot.t]
  @doc """
  Gets every slot from a motherboard
  """
  defdelegate get_slots(motherboard),
    to: MotherboardInternal

  @spec preload_components(Motherboard.t) ::
    Motherboard.t
  def preload_components(motherboard) do
    Repo.preload(motherboard, slots: :component)
  end

  @spec resources(Motherboard.t) ::
    %{
      cpu: non_neg_integer,
      ram: non_neg_integer,
      net: %{
        optional(HELL.PK.t) => %{
          uplink: non_neg_integer,
          downlink: non_neg_integer}}}
  # TODO: documentation
  defdelegate resources(motherboard),
    to: MotherboardInternal
end
