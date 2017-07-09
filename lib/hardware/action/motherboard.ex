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
  def link(motherboard_slot, component) do
    MotherboardInternal.link(motherboard_slot, component)
  end

  @spec unlink(MotherboardSlot.t) ::
    {:ok, MotherboardSlot.t}
    | {:error, Ecto.Changeset.t}
  @doc """
  Unlinks the component linked to motherboard slot

  This function is idempotent
  """
  def unlink(motherboard_slot) do
    MotherboardInternal.unlink(motherboard_slot)
  end

  @spec delete(Motherboard.t | HELL.PK.t) :: no_return
  @doc """
  Deletes the motherboard

  This function is idempotent, note that this effectively unlinks every
  component linked to motherboard's slots
  """
  def delete(motherboard) do
    MotherboardInternal.delete(motherboard)
  end
end
