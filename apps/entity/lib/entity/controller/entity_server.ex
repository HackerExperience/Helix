defmodule HELM.Entity.Controller.EntityServer do
  import Ecto.Query

  alias Ecto.Changeset
  alias HELM.Entity.Repo
  alias HELM.Entity.Model.EntityServer, as: MdlEntityServer

  @spec create(server_id :: MdlEntityServer.server_id , entity_id :: MdlEntityServer.entity_id) :: {:ok, MdlEntityServer.t} | {:error, Changeset.t}
  def create(server_id, entity_id) do
    %{server_id: server_id, entity_id: entity_id}
    |> MdlEntityServer.create_changeset()
    |> Repo.insert()
  end

  @spec find(server_id :: MdlEntityServer.server_id) :: {:ok, MdlEntityServer.t} | {:error, :notfound}
  def find(server_id) do
    case Repo.get_by(MdlEntityServer, server_id: server_id) do
      nil -> {:error, :notfound}
      res -> {:ok, res}
    end
  end

  @spec delete(server_id :: MdlEntityServer.server_id) :: :ok
  def delete(server_id) do
    MdlEntityServer
    |> where([s], s.server_id == ^server_id)
    |> Repo.delete_all()

    :ok
  end
end