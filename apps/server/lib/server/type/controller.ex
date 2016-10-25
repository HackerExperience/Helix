defmodule HELM.Server.Type.Controller do
  import Ecto.Query

  alias HELF.{Broker, Error}
  alias HELM.Server.Repo
  alias HELM.Server.Type.Schema, as: ServerTypeSchema

  def create(server_type) do
    ServerTypeSchema.create_changeset(%{server_type: server_type})
    |> Repo.insert()
  end

  def find(server_type) do
    case Repo.get_by(ServerTypeSchema, server_type: server_type) do
      nil -> {:error, :notfound}
      res -> {:ok, res}
    end
  end

  def delete(server_type) do
    with {:ok, serv_type} <- find(server_type),
         {:ok, _} <- Repo.delete(serv_type) do
      :ok
    else
      {:error, :notfound} -> :ok
    end
  end

  def all do
    ServerTypeSchema
    |> select([t], t.server_type)
    |> Repo.all
  end
end
