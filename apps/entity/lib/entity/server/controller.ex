defmodule HELM.Entity.Server.Controller do
  import Ecto.Query

  alias HELF.{Broker, Error}
  alias HELM.Entity.Repo
  alias HELM.Entity.Server.Schema, as: EntityServerSchema

  def create(server_id, entity_id) do
    %{server_id: server_id, entity_id: entity_id}
    |> EntityServerSchema.create_changeset
    |> do_create
  end

  def find(server_id) do
    case Repo.get_by(EntityServerSchema, server_id: server_id) do
      nil -> {:error, "Entity.Server not found."}
      res -> {:ok, res}
    end
  end

  def delete(server_id) do
    case find(server_id) do
      {:ok, server} -> do_delete(server)
      error -> error
    end
  end

  def do_create(changeset) do
    case Repo.insert(changeset) do
      {:ok, schema} ->
        {:ok, schema}
      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def do_delete(changeset) do
    case Repo.delete(changeset) do
      {:ok, result} -> {:ok, result}
      {:error, msg} -> {:error, msg}
    end
  end
end
