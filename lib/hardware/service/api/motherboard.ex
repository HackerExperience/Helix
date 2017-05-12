defmodule Helix.Hardware.Service.API.Motherboard do

  alias Helix.Hardware.Controller.Motherboard, as: MotherboardController
  alias Helix.Hardware.Model.Component
  alias Helix.Hardware.Model.Motherboard
  alias Helix.Hardware.Model.MotherboardSlot
  alias Helix.Hardware.Repo

  @spec fetch!(Component.t) :: Motherboard.t
  @doc """
  Fetches a motherboard by component
  """
  def fetch!(component) do
    MotherboardController.fetch!(component)
  end

  @spec get_slots(Motherboard.t | HELL.PK.t) :: [MotherboardSlot.t]
  @doc """
  Gets every slot from a motherboard
  """
  def get_slots(motherboard) do
    MotherboardController.get_slots(motherboard)
  end

  @spec preload_components(Motherboard.t) ::
    Motherboard.t
  def preload_components(motherboard) do
    Repo.preload(motherboard, slots: :component)
  end

  @spec link(MotherboardSlot.t, Component.t) ::
    {:ok, MotherboardSlot.t}
    | {:error, Ecto.Changeset.t}
  @doc """
  Links a component to given motherboard slot

  This function will fail if either the slot or component are attached
  """
  def link(motherboard_slot, component) do
    MotherboardController.link(motherboard_slot, component)
  end

  @spec unlink(MotherboardSlot.t) ::
    {:ok, MotherboardSlot.t}
    | {:error, Ecto.Changeset.t}
  @doc """
  Unlinks the component linked to motherboard slot

  This function is idempotent
  """
  def unlink(motherboard_slot) do
    MotherboardController.unlink(motherboard_slot)
  end

  @spec delete(Motherboard.t | HELL.PK.t) :: no_return
  @doc """
  Deletes the motherboard

  This function is idempotent, note that this effectively unlinks every
  component linked to motherboard's slots
  """
  def delete(motherboard) do
    MotherboardController.delete(motherboard)
  end
end
