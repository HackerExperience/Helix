defmodule Helix.Hardware.Controller.MotherboardSlot do

  alias Helix.Hardware.Model.Component
  alias Helix.Hardware.Model.MotherboardSlot
  alias Helix.Hardware.Repo

  @spec update(MotherboardSlot.t, MotherboardSlot.update_params) ::
    {:ok, MotherboardSlot.t}
    | {:error, Ecto.Changeset.t}
  def update(slot, params) do
    slot
    |> MotherboardSlot.update_changeset(params)
    |> Repo.update()
  end

  @spec link(MotherboardSlot.t, Component.t) ::
    {:ok, MotherboardSlot.t}
    | {:error, Ecto.Changeset.t}
  def link(slot, component) do
    params = %{link_component_id: component.component_id}

    slot
    |> MotherboardSlot.update_changeset(params)
    |> Repo.update()
  end

  @spec unlink(MotherboardSlot.t) ::
    {:ok, MotherboardSlot.t}
    | {:error, Ecto.Changeset.t}
  def unlink(slot) do
    update(slot, %{link_component_id: nil})
  end
end
