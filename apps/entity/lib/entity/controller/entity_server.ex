defmodule HELM.Entity.Controller.EntityServer do

  import Ecto.Query, only: [where: 3]

  alias HELM.Entity.Repo
  alias HELM.Entity.Model.Entity, as: MdlEntity, warn: false
  alias HELM.Server.Model.Server, as: MdlServer
  alias HELM.Entity.Model.EntityServer, as: MdlEntityServer

  @spec create(MdlEntity.id, MdlServer.id) :: {:ok, MdlEntityServer.t} | {:error, Ecto.Changeset.t}
  def create(entity_id, server_id) do
    %{server_id: server_id, entity_id: entity_id}
    |> MdlEntityServer.create_changeset()
    |> Repo.insert()
  end

  @spec find(MdlEntity.id, MdlServer.id) :: {:ok, MdlEntityServer.t} | {:error, :notfound}
  def find(entity_id, server_id) do
    case Repo.get_by(MdlEntityServer, server_id: server_id, entity_id: entity_id) do
      nil -> {:error, :notfound}
      res -> {:ok, res}
    end
  end

  @spec delete(MdlEntity.id, MdlServer.id) :: :ok
  def delete(entity_id, server_id) do
    MdlEntityServer
    |> where([s], s.entity_id == ^entity_id and s.server_id == ^server_id)
    |> Repo.delete_all()

    :ok
  end
end