defmodule HELM.Entity.Controller.Entities do
  import Ecto.Query

  alias HELF.{Broker, Error}
  alias HELM.Entity.Model.Entities, as: MdlEntities
  alias HELM.Entity.Model.Repo

  def create(struct) do
    %{entity_type: struct.entity_type, reference_id: struct.reference_id}
    |> MdlEntities.create_changeset
    |> do_create
  end

  def find(entity_id) do
    case Repo.get_by(MdlEntities, entity_id: entity_id) do
      nil -> {:error, :notfound}
      entity -> {:ok, entity}
    end
  end

  def delete(entity_id) do
    with {:ok, entity} <- find(entity_id),
         {:ok, _} <- Repo.delete(entity) do
      :ok
    else
      {:error, :notfound} -> :ok
    end
  end

  defp do_create(changeset) do
    case Repo.insert(changeset) do
      {:ok, schema} ->
        Broker.cast("event:entity:created", changeset.changes.entity_id)
        {:ok, schema}
      {:error, changeset} ->
        {:error, changeset}
    end
  end
end