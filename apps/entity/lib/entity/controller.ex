defmodule HELM.Entity.Controller do
  import Ecto.Query

  alias HELF.{Broker, Error}
  alias HELM.Entity

  @doc ~S"""
    Creates a new entity for given `account_id`
  """
  def new_entity(%{account_id: account_id}) do
    Entity.Schema.create_changeset(%{account_id: account_id})
    |> do_new_entity
  end

  @doc ~S"""
    Creates a new entity for given `npc_id`
  """
  def new_entity(%{npc_id: npc_id}) do
  end

  @doc ~S"""
    Creates a new entity for given `clan_id`
  """
  def new_entity(%{clan_id: clan_id}) do
  end

  @doc ~S"""
    Creates a new entity for given changeset
  """
  defp do_new_entity(changeset) do
    case Entity.Repo.insert(changeset) do
      {:ok, schema} ->
        Broker.cast("event:entity:created", changeset.changes.entity_id)
        {:ok, schema}
      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def find(entity_id) do
    case Entity.Repo.get_by(Entity.Schema, entity_id: entity_id) do
      nil -> {:error, Error.format_reply(:not_found, "Entity not found")}
      res -> {:ok, res}
    end
  end


  def find_by(struct) do
    case Entity.Repo.get_by(Entity.Schema, struct) do
      nil -> {:error, Error.format_reply(:not_found, "Entity not found")}
      res -> {:ok, res}
    end
  end

  def remove_entity(entity) do
    case Entity.Repo.delete(entity) do
      {:ok, result} -> {:ok, result}
      {:error, msg} -> {:error, msg}
    end
  end
end
