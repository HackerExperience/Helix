defmodule HELM.Hardware.Controller.Motherboard do
  import Ecto.Query

  alias HELF.Broker
  alias HELM.Hardware.Model.Repo
  alias HELM.Hardware.Model.Motherboards, as: MdlMobo

  def create do
    MdlMobo.create_changeset()
    |> do_create()
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

  def do_create(changeset) do
    case Repo.insert(changeset) do
      {:ok, schema} ->
        Broker.cast("event:component:motherboard:created", schema.motherboard_id)
        {:ok, schema}
      {:error, msg} ->
        {:error, msg}
    end
  end
end