defmodule HELM.Server.Type.Controller do
  import Ecto.Query

  alias HELF.{Broker, Error}
  alias HELM.Server.Repo
  alias HELM.Server.Type.Schema, as: ServerTypeSchema

  def create(server_type) do
    ServerTypeSchema.create_changeset(%{server_type: server_type})
    |> do_create
  end

  def find(server_type) do
    case Repo.get_by(ServerTypeSchema, server_type: server_type) do
      nil -> {:error, "Server.Type not found."}
      res -> {:ok, res}
    end
  end

  def all do
    ServerTypeSchema
    |> select([t], t.server_type)
    |> Repo.all
  end

  def delete(server_type) do
    case find(server_type) do
      {:ok, serv_type} -> do_delete(serv_type)
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

  defp do_delete(serv_type) do
    case Repo.delete(serv_type) do
      {:ok, result} -> {:ok, result}
      {:error, msg} -> {:error, msg}
    end
  end
end
