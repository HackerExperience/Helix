defmodule HELM.Hardware.Motherboard.Controller do
  import Ecto.Query

  alias HELF.{Broker, Error}
  alias HELM.Hardware.Repo
  alias HELM.Hardware.Motherboard.Schema, as: MoboSchema

  def create do
    MoboSchema.create_changeset
    |> do_create
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

  def find(motherboard_id) do
    case Repo.get_by(MoboSchema, motherboard_id: motherboard_id) do
      nil -> {:error, "Motherboard not found."}
      res -> {:ok, res}
    end
  end

  def delete(motherboard_id) do
    case find(motherboard_id) do
      {:ok, mobo} -> do_delete(mobo)
      error -> error
    end
  end

  defp do_delete(motherboard) do
    case Repo.delete(motherboard) do
      {:ok, result} -> {:ok, result}
      {:error, msg} -> {:error, msg}
    end
  end
end
