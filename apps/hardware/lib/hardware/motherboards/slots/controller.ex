defmodule HELM.Hardware.Motherboard.Slot.Controller do
  import Ecto.Query

  alias HELF.{Broker, Error}
  alias HELM.Hardware.Repo
  alias HELM.Hardware.Motherboard.Slot.Schema, as: MoboSlotSchema

  def create(motherboard_id, internal_id, component_type, component_id) do
    %{slot_internal_id: internal_id,
      motherboard_id: motherboard_id,
      link_component_type: component_type,
      link_component_id: component_id}
    |> MoboSlotSchema.create_changeset
    |> do_create
  end

  def find(slot_id) do
    case Repo.get_by(MoboSlotSchema, slot_id: slot_id) do
      nil -> {:error, "Motherboard.Slot not found."}
      res -> {:ok, res}
    end
  end

  def delete(slot_id) do
    case find(slot_id) do
      {:ok, slot} -> do_delete(slot)
      error -> error
    end
  end

  defp do_create(changeset) do
    case Repo.insert(changeset) do
      {:ok, schema} ->
        Broker.cast("event:component:motherboard:slot:created", changeset.changes.slot_id)
        {:ok, schema}
      {:error, error} ->
        {:error, error}
    end
  end

  defp do_delete(slot) do
    case Repo.delete(slot) do
      {:ok, result} -> {:ok, result}
      {:error, msg} -> {:error, msg}
    end
  end
end
