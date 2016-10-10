defmodule HELM.Hardware.Motherboard.Controller do
  import Ecto.Query

  alias HELF.{Broker, Error}
  alias HELM.Hardware.Repo
  alias HELM.Hardware.Motherboard.Schema, as: MoboSchema

  def new_motherboard do
    MoboSchema.create_changeset
    |> do_new_motherboard
  end

  def attach(motherboard_id, server_id) do
    # WIP
  end

  def do_new_motherboard(changeset) do
    case Repo.insert(changeset) do
      {:ok, schema} ->
        Broker.cast("event:component:motherboard:created", changeset.changes.motherboard_id)
        {:ok, schema}
      {:error, msg} ->
        {:error, msg}
    end
  end

  def detach(motherboard_id) do
    # WIP
  end

  def find_motherboard(motherboard_id) do
    case Repo.get_by(MoboSchema, motherboard_id: motherboard_id) do
      nil -> {:error, "Motherboard not found."}
      res -> {:ok, res}
    end
  end

  def delete_motherboard(motherboard_id) do
    case find_motherboard(motherboard_id) do
      {:ok, mobo} -> do_delete_motherboard(mobo)
      error -> error
    end
  end

  defp do_delete_motherboard(motherboard) do
    case Repo.delete(motherboard) do
      {:ok, result} -> {:ok, result}
      {:error, msg} -> {:error, msg}
    end
  end
end
