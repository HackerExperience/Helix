defmodule HELM.Hardware.Controller.Motherboard do
  import Ecto.Query

  alias HELF.Broker
  alias HELM.Hardware.Repo
  alias HELM.Hardware.Model.Motherboards, as: MdlMobo

  def create do
    MdlMobo.create_changeset()
    |> Repo.insert()
  end

  def find(motherboard_id) do
    case Repo.get_by(MdlMobo, motherboard_id: motherboard_id) do
      nil -> {:error, :notfound}
      res -> {:ok, res}
    end
  end

  def delete(motherboard_id) do
    MdlMobo
    |> where([s], s.motherboard_id == ^motherboard_id)
    |> Repo.delete_all()

    :ok
  end
end