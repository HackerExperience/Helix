defmodule HELM.Hardware.Controller.MotherboardSlot do

  alias HELM.Hardware.Repo
  alias HELM.Hardware.Model.MotherboardSlot, as: MdlMoboSlot
  import Ecto.Query, only: [where: 3]

  @spec create(MdlMoboSlot.creation_params) :: {:ok, MdlMoboSlot.t} | {:error, Ecto.Changeset.t}
  def create(params) do
    params
    |> MdlMoboSlot.create_changeset()
    |> Repo.insert()
  end

  @spec find(HELL.PK.t) :: {:ok, MdlMoboSlot.t} | {:error, :notfound}
  def find(slot_id) do
    case Repo.get_by(MdlMoboSlot, slot_id: slot_id) do
      nil ->
        {:error, :notfound}
      res ->
        {:ok, res}
    end
  end

  @spec update(HELL.PK.t, MdlMoboSlot.update_params) :: {:ok, MdlMoboSlot.t} | {:error, :notfound | Ecto.Changeset.t}
  def update(slot_id, params) do
    with {:ok, mobo_slot} <- find(slot_id) do
      mobo_slot
      |> MdlMoboSlot.update_changeset(params)
      |> Repo.update()
    end
  end

  @spec link(slot :: HELL.PK.t, component :: HELL.PK.t | nil) :: {:ok, MdlMoboSlot.t} | {:error, Ecto.Changeset.t} | {:error, :notfound}
  def link(slot_id, link_component_id) do
    with {:ok, slot} <- find(slot_id) do
      slot
      |> MdlMoboSlot.update_changeset(%{link_component_id: link_component_id})
      |> Repo.update()
    end
  end

  @spec unlink(HELL.PK.t) :: {:ok, MdlMoboSlot.t} | {:error, Ecto.Changeset.t} | {:error, :notfound}
  def unlink(slot_id) do
    link(slot_id, nil)
  end

  @spec delete(HELL.PK.t) :: no_return
  def delete(slot_id) do
    MdlMoboSlot
    |> where([s], s.slot_id == ^slot_id)
    |> Repo.delete_all()

    :ok
  end
end