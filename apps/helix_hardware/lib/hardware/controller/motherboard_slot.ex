defmodule Helix.Hardware.Controller.MotherboardSlot do

  alias Helix.Hardware.Model.Component
  alias Helix.Hardware.Model.MotherboardSlot
  alias Helix.Hardware.Repo

  @spec find(HELL.PK.t) :: {:ok, MotherboardSlot.t} | {:error, :notfound}
  def find(slot_id) do
    case Repo.get_by(MotherboardSlot, slot_id: slot_id) do
      nil ->
        {:error, :notfound}
      res ->
        {:ok, res}
    end
  end

  @spec update(MotherboardSlot.t, MotherboardSlot.update_params) :: {:ok, MotherboardSlot.t} | {:error, Ecto.Changeset.t}
  def update(slot, params) do
    slot
    |> MotherboardSlot.update_changeset(params)
    |> Repo.update()
  end

  @spec link(MotherboardSlot.t, Component.t) ::
    {:ok, MotherboardSlot.t}
    | {:error, :component_already_linked | :slot_already_linked, Ecto.Changeset.t}
  def link(slot, component) do
    slot_linked? = fn slot ->
      MotherboardSlot.linked?(slot) && {:error, :slot_already_linked}
    end

    component_used? = fn component ->
      component_used?(component) && {:error, :component_already_linked}
    end

    with \
      false <- slot_linked?.(slot),
      false <- component_used?.(component)
    do
      params = %{link_component_id: component.component_id}

      slot
      |> MotherboardSlot.update_changeset(params)
      |> Repo.update()
    end
  end

  @spec unlink(MotherboardSlot.t) :: {:ok, MotherboardSlot.t} | {:error, Ecto.Changeset.t}
  def unlink(slot) do
    update(slot, %{link_component_id: nil})
  end

  @spec component_used?(Component.t) :: boolean
  defp component_used?(component) do
    component
    |> Repo.preload(:slot)
    |> Map.fetch!(:slot)
    |> to_boolean()
  end

  @spec to_boolean(term) :: boolean
  defp to_boolean(v),
    do: !!v
end
