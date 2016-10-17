defmodule HELM.Entity.Type.Controller do
  import Ecto.Query

  alias HELF.{Broker, Error}
  alias HELM.Entity.Repo
  alias HELM.Entity.Type.Schema, as: EntityTypeSchema

  def create(type_name) do
    %{entity_type: type_name}
    |> EntityTypeSchema.create_changeset
    |> do_create
  end

  def find(type_name) do
    case Repo.get_by(EntityTypeSchema, entity_type: type_name) do
      nil -> {:error, "Entity.Type not found."}
      res -> {:ok, res}
    end
  end

  def delete(type_name) do
    case find(type_name) do
      {:ok, entity_type} -> do_delete(entity_type)
      error -> error
    end
  end

  defp do_create(changeset) do
    case Repo.insert(changeset) do
      {:ok, schema} ->
        {:ok, schema}
      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp do_delete(changeset) do
    case Repo.delete(changeset) do
      {:ok, result} -> {:ok, result}
      {:error, msg} -> {:error, msg}
    end
  end
end
