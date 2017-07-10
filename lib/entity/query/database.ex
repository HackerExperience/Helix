defmodule Helix.Entity.Query.Database do

  alias Helix.Server.Model.Server
  alias Helix.Entity.Internal.Database, as: DatabaseInternal
  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Repo

  @spec get_database(Entity.t) ::
    [map]
  def get_database(entity) do
    entity
    |> DatabaseInternal.get_database()
    |> Repo.all()
  end

  @spec fetch_server_record(Entity.t, Server.id) ::
    map
    | nil
  def fetch_server_record(entity, server) do
    entity
    |> DatabaseInternal.get_entry_by_server_id(server)
    |> DatabaseInternal.select_for_presentation()
    |> Repo.one()
  end
end
