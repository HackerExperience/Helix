defmodule HELM.Entity.Controller do
  import Ecto.Query

  alias HELF.{Broker, Error}
  alias HELM.Entity.Schema, as: EntitySchema
  alias HELM.Entity.Repo

  def create(%{account_id: account_id}) do
    EntitySchema.create_changeset(%{account_id: account_id})
    |> do_create
  end

  def create(%{npc_id: npc_id}) do
    EntitySchema.create_changeset(%{npc_id: npc_id})
    |> do_create
  end

  def create(%{clan_id: clan_id}) do
    EntitySchema.create_changeset(%{clan_id: clan_id})
    |> do_create
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

  def find(entity_id) do
    case Repo.get_by(EntitySchema, entity_id: entity_id) do
      nil -> {:error, Error.format_reply(:not_found, "Entity not found")}
      res -> {:ok, res}
    end
  end


  def find_by(struct) do
    case Repo.get_by(EntitySchema, struct) do
      nil -> {:error, Error.format_reply(:not_found, "Entity not found")}
      res -> {:ok, res}
    end
  end

  def delete(entity_id) do
    case find(entity_id) do
      {:ok, entity} -> do_delete(entity)
      error -> error
    end
  end

  def do_delete(entity) do
    case Repo.delete(entity) do
      {:ok, result} -> {:ok, result}
      {:error, msg} -> {:error, msg}
    end
  end
end
