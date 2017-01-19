defmodule Helix.Hardware.Controller.MotherboardSlot do

  alias Helix.Hardware.Controller.Component, as: ComponentController
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

  @spec find_by([{:motherboard_id, HELL.PK.t}]) :: [MotherboardSlot.t]
  def find_by(motherboard_id: motherboard_id) do
    motherboard_id
    |> MotherboardSlot.Query.by_motherboard_id()
    |> Repo.all()
  end

  @spec update(HELL.PK.t, MotherboardSlot.update_params) :: {:ok, MotherboardSlot.t} | {:error, :notfound | Ecto.Changeset.t}
  def update(slot_id, params) do
    with {:ok, mobo_slot} <- find(slot_id) do
      mobo_slot
      |> MotherboardSlot.update_changeset(params)
      |> Repo.update()
    end
  end

  @spec link(slot_id :: HELL.PK.t, component :: HELL.PK.t) ::
    {:ok, MotherboardSlot.t}
    | {:error, :component_already_linked | :slot_already_linked | :notfound | Ecto.Changeset.t}
  def link(slot_id, component_id) do
    slot_linked? = fn slot ->
      MotherboardSlot.linked?(slot)
      && {:error, :slot_already_linked}
      || false
    end

    component_used? = fn component ->
      component_used?(component.component_id)
      && {:error, :component_already_linked}
      || false
    end

    with \
      {:ok, slot} <- find(slot_id),
      {:ok, component} <- ComponentController.find(component_id),
      false <- slot_linked?.(slot),
      false <- component_used?.(component)
    do
      slot
      |> MotherboardSlot.update_changeset(%{link_component_id: component_id})
      |> Repo.update()
    end
  end

  @spec unlink(HELL.PK.t) :: {:ok, MotherboardSlot.t} | {:error, :notfound | Ecto.Changeset.t}
  def unlink(slot_id) do
    update(slot_id, %{link_component_id: nil})
  end

  @spec component_used?(HELL.PK.t) :: boolean
  defp component_used?(component_id) do
    component_id
    |> MotherboardSlot.Query.by_component_id()
    # We are selecting only the component_id to reduce the query time as this
    # query uses a single indexed field and nothing else
    |> MotherboardSlot.Query.select_component_id()
    |> Repo.one()
    |> to_boolean()
  end

  @spec to_boolean(term) :: boolean
  defp to_boolean(v),
    do: !!v
end