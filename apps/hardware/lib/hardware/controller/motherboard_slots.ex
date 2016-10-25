defmodule HELM.Hardware.Controller.MotherboardSlots do
  import Ecto.Query

  alias Ecto.Changeset
  alias HELF.{Broker, Error}
  alias HELM.Hardware.Model.Repo
  alias HELM.Hardware.Model.MotherboardSlots, as: MdlMoboSlots

  def create(params) do
    MdlMoboSlots.create_changeset(params)
    |> do_create
  end

  def find(slot_id) do
    case Repo.get_by(MdlMoboSlots, slot_id: slot_id) do
      nil -> {:error, :notfound}
      res -> {:ok, res}
    end
  end

  def link(slot_id, link_component_id) do
    with {:ok, slot} <- find(slot_id) do
      MdlMoboSlots.update_changeset(slot, %{link_component_id: link_component_id})
      |> do_update
    else
      _ -> {:error, :notfound}
    end
  end

  def unlink(slot_id) do
    link(slot_id, nil)
  end

  def delete(slot_id) do
    with {:ok, slot} <- find(slot_id),
         {:ok, _} <- Repo.delete(slot) do
      :ok
    else
      {:error, :notfound} -> :ok
    end
  end

  defp do_create(changeset) do
    case Repo.insert(changeset) do
      {:ok, schema} ->
        Broker.cast("event:component:motherboard:slot:created", changeset.changes.slot_id)
        {:ok, schema}
      {:error, msg} ->
        {:error, msg}
    end
  end

  defp do_update(changeset) do
    case Repo.update(changeset) do
      {:ok, schema} -> {:ok, schema}
      {:error, msg} -> {:error, msg}
    end
  end
end