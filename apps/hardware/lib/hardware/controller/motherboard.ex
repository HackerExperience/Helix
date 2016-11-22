defmodule HELM.Hardware.Controller.Motherboard do

  alias HELM.Hardware.Repo
  alias HELM.Hardware.Model.Motherboard, as: MdlMobo
  import Ecto.Query, only: [where: 3]

  @spec create() :: {:ok, MdlMobo.t} | {:error, Ecto.Changeset.t}
  def create do
    MdlMobo.create_changeset()
    |> Repo.insert()
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
    MdlMobo
    |> where([m], m.motherboard_id == ^motherboard_id)
    |> Repo.delete_all()

    :ok
  end
end