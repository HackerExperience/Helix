defmodule HELM.Entity.Controller.EntityServer do
  import Ecto.Query

  alias HELF.{Broker, Error}
  alias HELM.Entity.Model.Repo
  alias HELM.Entity.Model.EntityServer, as: MdlEntityServer

  def create(server_id, entity_id) do
    %{server_id: server_id, entity_id: entity_id}
    |> MdlEntityServer.create_changeset()
    |> Repo.insert()
  end

  def find(server_id) do
    case Repo.get_by(MdlEntityServer, server_id: server_id) do
      nil -> {:error, :notfound}
      res -> {:ok, res}
    end
  end

  def delete(server_id) do
    MdlEntityServer
    |> where([s], s.server_id == ^server_id)
    |> Repo.delete_all()

    :ok
  end
end