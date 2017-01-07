defmodule Helix.Entity.Controller.EntityServer do

  alias Helix.Entity.Repo
  alias Helix.Entity.Model.Entity, as: MdlEntity, warn: false
  alias Helix.Server.Model.Server, as: MdlServer
  alias Helix.Entity.Model.EntityServer, as: MdlEntityServer
  import Ecto.Query, only: [where: 3]

  @spec create(MdlEntity.id, MdlServer.id) :: {:ok, MdlEntityServer.t} | {:error, Ecto.Changeset.t}
  def create(entity_id, server_id) do
    %{entity_id: entity_id, server_id: server_id}
    |> MdlEntityServer.create_changeset()
    |> Repo.insert()
  end

  @spec find(MdlEntity.id) :: [MdlEntityServer.t]
  def find(entity_id) do
    MdlEntityServer
    |> where([s], s.entity_id == ^entity_id)
    |> Repo.all()
  end

  @spec delete(MdlEntity.id, MdlServer.id) :: no_return
  def delete(entity_id, server_id) do
    MdlEntityServer
    |> where([s], s.entity_id == ^entity_id)
    |> where([s], s.server_id == ^server_id)
    |> Repo.delete_all()

    :ok
  end
end