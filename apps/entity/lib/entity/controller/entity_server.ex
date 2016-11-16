defmodule HELM.Entity.Controller.EntityServer do

  import Ecto.Query, only: [where: 3]

  alias HELM.Entity.Repo
  alias HELM.Entity.Model.Entity, as: MdlEntity, warn: false
  alias HELM.Entity.Model.EntityServer, as: MdlEntityServer

  @spec create(MdlEntityServer.server_id, MdlEntity.id) :: {:ok, MdlEntityServer.t} | {:error, Ecto.Changeset.t}
  def create(server_id, entity_id) do
    %{server_id: server_id, entity_id: entity_id}
    |> MdlEntityServer.create_changeset()
    |> Repo.insert()
  end

  @spec find(MdlEntityServer.server_id) :: {:ok, MdlEntityServer.t} | {:error, :notfound}
  def find(server_id) do
    case Repo.get_by(MdlEntityServer, server_id: server_id) do
      nil -> {:error, :notfound}
      res -> {:ok, res}
    end
  end

  @spec delete(MdlEntityServer.server_id) :: :ok
  def delete(server_id) do
    MdlEntityServer
    |> where([s], s.server_id == ^server_id)
    |> Repo.delete_all()

    :ok
  end
end