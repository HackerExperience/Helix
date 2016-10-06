defmodule HELM.Hardware.Motherboard.Controller do
  import Ecto.Query

  alias HELF.{Broker, Error}
  alias HELM.Hardware
  alias HELM.Hardware.Motherboard

  def new do
    Motherboard.Schema.create_changeset
    |> do_new_mobo
  end

  def do_new_mobo(changeset) do
    case Hardware.Repo.insert(changeset) do
      {:ok, schema} ->
        Broker.cast("event:component:motherboard:created", changeset.changes.motherboard_id)
        {:ok, schema}
      {:error, msg} ->
        {:error, msg}
    end
  end

  def find(motherboard_id) do
    case Hardware.Repo.get_by(Motherboard.Schema, motherboard_id: motherboard_id) do
      nil -> {:error, "Motherboard not found."}
      res -> {:ok, res}
    end
  end

  def remove(motherboard) do
    case Hardware.Repo.delete(motherboard) do
      {:ok, result} -> {:ok, result}
      {:error, msg} -> {:error, msg}
    end
  end
end
