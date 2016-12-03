defmodule HELM.Hardware.Controller.Motherboard do

  alias HELM.Hardware.Repo
  alias HELM.Hardware.Controller.MotherboardSlot, as: CtrlMoboSlot
  alias HELM.Hardware.Model.Motherboard, as: MdlMobo

  import Ecto.Query, only: [where: 3]

  @spec create(MdlMobo.creation_params) :: {:ok, MdlMobo.t} | {:error, Ecto.Changeset.t}
  def create(params) do
    Repo.transaction fn ->
      motherboard =
        params
        |> MdlMobo.create_changeset()
        |> Repo.insert!()
        |> Repo.preload(:component_spec)

      Enum.each(motherboard.component_spec.spec["slots"], fn {id, slot_spec} ->
        slot = %{
          motherboard_id: motherboard.motherboard_id,
          slot_internal_id: id,
          link_component_type: slot_spec["type"]
        }
        {:ok, _} = CtrlMoboSlot.create(slot)
      end)

      motherboard
    end
  end

  @spec find(HELL.PK.t) :: {:ok, MdlMobo.t} | {:error, :notfound}
  def find(motherboard_id) do
    case Repo.get_by(MdlMobo, motherboard_id: motherboard_id) do
      nil ->
        {:error, :notfound}
      res ->
        {:ok, res}
    end
  end

  @spec delete(HELL.PK.t) :: no_return
  def delete(motherboard_id) do
    {status, _} =
      Repo.transaction fn ->
        CtrlMoboSlot.delete_by(motherboard_id: motherboard_id)

        MdlMobo
        |> where([m], m.motherboard_id == ^motherboard_id)
        |> Repo.delete_all()

        :ok
      end
    status
  end
end