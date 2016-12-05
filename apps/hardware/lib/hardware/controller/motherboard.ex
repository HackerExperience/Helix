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

      motherboard.component_spec
      |> CtrlMoboSlot.parse_motherboard_spec()
      |> Enum.map(&Map.put(&1, :motherboard_id, motherboard.motherboard_id))
      |> Enum.each(&CtrlMoboSlot.create/1)

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