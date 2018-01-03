defmodule Helix.Story.Internal.Manager do

  alias Helix.Entity.Model.Entity
  alias Helix.Network.Model.Network
  alias Helix.Server.Model.Server
  alias Helix.Story.Model.Story
  alias Helix.Story.Repo

  @spec fetch(Entity.id) ::
    Story.Manager.t
    | nil
  def fetch(entity_id = %Entity.ID{}) do
    entity_id
    |> Story.Manager.Query.by_entity()
    |> Repo.one()
  end

  @spec setup(Entity.t, Server.t, Network.t) ::
    {:ok, Story.Manager.t}
    | {:error, Story.Manager.changeset}
  def setup(entity = %Entity{}, server = %Server{}, network = %Network{}) do
    params =
      %{
        entity_id: entity.entity_id,
        server_id: server.server_id,
        network_id: network.network_id
      }

    params
    |> Story.Manager.create()
    |> Repo.insert()
  end

  @spec remove(Story.Manager.t) ::
    :ok
  def remove(manager = %Story.Manager{}) do
    manager
    |> Repo.delete()

    :ok
  end
end
