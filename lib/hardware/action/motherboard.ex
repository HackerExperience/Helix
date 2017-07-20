defmodule Helix.Hardware.Action.Motherboard do

  alias Helix.Hardware.Internal.Motherboard, as: MotherboardInternal
  alias Helix.Hardware.Model.Component
  alias Helix.Hardware.Model.Motherboard
  alias Helix.Hardware.Model.MotherboardSlot

  @spec link(MotherboardSlot.t, Component.t) ::
    {:ok, MotherboardSlot.t}
    | {:error, Ecto.Changeset.t}
  @doc """
  Links a component to given motherboard slot

  This function will fail if either the slot or component are attached
  """
  defdelegate link(motherboard_slot, component),
    to: MotherboardInternal

  @spec unlink(MotherboardSlot.t) ::
    {:ok, MotherboardSlot.t}
  @doc """
  Unlinks the component linked to motherboard slot

  This function is idempotent
  """
  defdelegate unlink(motherboard_slot),
    to: MotherboardInternal

  @spec delete(Motherboard.t | Motherboard.id) ::
    :ok
  @doc """
  Deletes the motherboard

  This function is idempotent, note that this effectively unlinks every
  component linked to motherboard's slots
  """
  defdelegate delete(motherboard),
    to: MotherboardInternal
end
