defmodule HELM.Hardware.Controller.MotherboardSlot do

  import Ecto.Query

  alias HELM.Hardware.Repo
  alias HELM.Hardware.Model.MotherboardSlot, as: MdlMoboSlot

  def create(params) do
    MdlMoboSlot.create_changeset(params)
    |> Repo.insert()
  end

  def find(slot_id) do
    case Repo.get_by(MdlMoboSlot, slot_id: slot_id) do
      nil -> {:error, :notfound}
      res -> {:ok, res}
    end
  end

  def link(slot_id, link_component_id) do
    with {:ok, slot} <- find(slot_id) do
      MdlMoboSlot.update_changeset(slot, %{link_component_id: link_component_id})
      |> Repo.update()
    else
      _ -> {:error, :notfound}
    end
  end

  def unlink(slot_id) do
    link(slot_id, nil)
  end

  def delete(slot_id) do
    MdlMoboSlot
    |> where([s], s.slot_id == ^slot_id)
    |> Repo.delete_all()

    :ok
  end
end