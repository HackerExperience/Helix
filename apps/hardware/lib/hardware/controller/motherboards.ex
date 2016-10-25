defmodule HELM.Hardware.Controller.Motherboards do
  import Ecto.Query

  alias HELF.{Broker, Error}
  alias HELM.Hardware.Model.Repo
  alias HELM.Hardware.Model.Motherboards, as: MdlMobos

  def create do
    MdlMobos.create_changeset()
    |> do_create()
  end

  def find(motherboard_id) do
    case Repo.get_by(MdlMobos, motherboard_id: motherboard_id) do
      nil -> {:error, :notfound}
      res -> {:ok, res}
    end
  end

  def delete(motherboard_id) do
    with {:ok, mobo} <- find(motherboard_id),
         {:ok, _} <- Repo.delete(mobo) do
      :ok
    else
      {:error, :notfound} -> :ok
    end
  end

  def do_create(changeset) do
    case Repo.insert(changeset) do
      {:ok, schema} ->
        Broker.cast("event:component:motherboard:created", changeset.changes.motherboard_id)
        {:ok, schema}
      {:error, msg} ->
        {:error, msg}
    end
  end
end