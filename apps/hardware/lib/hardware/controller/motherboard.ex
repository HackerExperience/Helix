defmodule Helix.Hardware.Controller.Motherboard do

  alias Helix.Hardware.Repo
  alias Helix.Hardware.Model.Motherboard, as: MdlMobo

  import Ecto.Query, only: [where: 3]

  @spec create(MdlMobo.creation_params) :: {:ok, MdlMobo.t} | no_return
  def create(params) do
    Repo.transaction fn ->
      params
      |> MdlMobo.create_changeset()
      |> Repo.insert()
      |> case do
        {:ok, mb} ->
          mb
        _ ->
          Repo.rollback("TODO: Reason")
      end
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
    {status, _} = Repo.transaction fn ->
      MdlMobo
      |> where([m], m.motherboard_id == ^motherboard_id)
      |> Repo.delete_all()
    end

    status
  end
end