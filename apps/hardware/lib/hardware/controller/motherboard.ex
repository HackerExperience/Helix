defmodule Helix.Hardware.Controller.Motherboard do

  alias Helix.Hardware.Model.Motherboard
  alias Helix.Hardware.Model.MotherboardSlot
  alias Helix.Hardware.Repo

  import Ecto.Query, only: [where: 3]

  @spec create(Motherboard.creation_params) :: {:ok, Motherboard.t} | no_return
  def create(params) do
    Repo.transaction fn ->
      motherboard = Motherboard.create_changeset(params)

      case Repo.insert(motherboard) do
        {:ok, mb} ->
          mb
        _ ->
          # TODO: Proper error message
          Repo.rollback(:internal_error)
      end
    end
  end

  @spec find(HELL.PK.t) :: {:ok, Motherboard.t} | {:error, :notfound}
  def find(motherboard_id) do
    case Repo.get_by(Motherboard, motherboard_id: motherboard_id) do
      nil ->
        {:error, :notfound}
      res ->
        {:ok, res}
    end
  end

  @spec get_slots(HELL.PK.t) :: [MotherboardSlot.t]
  def get_slots(motherboard_id) do
    MotherboardSlot
    |> where([s], s.motherboard_id == ^motherboard_id)
    |> Repo.all()
  end

  @spec delete(HELL.PK.t) :: no_return
  def delete(motherboard_id) do
    {status, _} = Repo.transaction fn ->
      Motherboard
      |> where([m], m.motherboard_id == ^motherboard_id)
      |> Repo.delete_all()
    end

    status
  end
end