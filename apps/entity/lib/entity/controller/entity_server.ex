defmodule Helix.Entity.Controller.EntityServer do

  alias Helix.Entity.Repo
  alias Helix.Entity.Model.Entity
  alias Helix.Server.Model.Server
  alias Helix.Entity.Model.EntityServer
  import Ecto.Query, only: [where: 3]

  @spec create(Entity.id, Server.id) :: {:ok, EntityServer.t} | {:error, Ecto.Changeset.t}
  def create(entity_id, server_id) do
    %{entity_id: entity_id, server_id: server_id}
    |> EntityServer.create_changeset()
    |> Repo.insert()
  end

  @spec find(Entity.id) :: [EntityServer.t]
  def find(entity_id) do
    EntityServer
    |> where([s], s.entity_id == ^entity_id)
    |> Repo.all()
  end

  @spec delete(Entity.id, Server.id) :: no_return
  def delete(entity_id, server_id) do
    EntityServer
    |> where([s], s.entity_id == ^entity_id)
    |> where([s], s.server_id == ^server_id)
    |> Repo.delete_all()

    :ok
  end
end