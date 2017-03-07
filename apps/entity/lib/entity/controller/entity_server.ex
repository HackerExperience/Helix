defmodule Helix.Entity.Controller.EntityServer do

  alias Helix.Server.Model.Server
  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Model.EntityServer
  alias Helix.Entity.Repo

  import Ecto.Query, only: [select: 3]

  @spec create(Entity.t | Entity.id, Server.id) ::
    {:ok, EntityServer.t} | {:error, Ecto.Changeset.t}
  def create(entity = %Entity{}, server_id),
    do: create(entity.entity_id, server_id)
  def create(entity_id, server_id) do
    %{entity_id: entity_id, server_id: server_id}
    |> EntityServer.create_changeset()
    |> Repo.insert()
  end

  @spec find(Entity.t | Entity.id) :: [PK.t]
  def find(entity) do
    entity
    |> EntityServer.Query.from_entity()
    |> select([es], es.server_id)
    |> Repo.all()
  end

  @spec delete(Entity.t | Entity.id, Server.id) :: no_return
  def delete(entity, server_id) do
    entity
    |> EntityServer.Query.from_entity()
    |> EntityServer.Query.by_server_id(server_id)
    |> Repo.delete_all()

    :ok
  end
end