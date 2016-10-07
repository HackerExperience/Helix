defmodule HELM.Hardware.Motherboard.Controller do
  import Ecto.Query

  alias HELF.{Broker, Error}
  alias HELM.Hardware
  alias HELM.Hardware.Motherboard

  def new_motherboard do
    Motherboard.Schema.create_changeset
    |> do_new_motherboard
  end

  def attach(motherboard_id, server_id) do
    # WIP
  end

  def do_new_motherboard(changeset) do
    case Hardware.Repo.insert(changeset) do
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
    case Hardware.Repo.get_by(Motherboard.Schema, motherboard_id: motherboard_id) do
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
    case Hardware.Repo.delete(motherboard) do
      {:ok, result} -> {:ok, result}
      {:error, msg} -> {:error, msg}
    end
  end
end
