defmodule Helix.Entity.Query.HackDatabase do

  alias Helix.Server.Model.Server
  alias Helix.Entity.Internal.HackDatabase, as: HackDatabaseInternal
  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Repo

  @spec get_database(Entity.t) ::
    [map]
  def get_database(entity) do
    entity
    |> HackDatabaseInternal.get_database()
    |> Repo.all()
  end

  @spec fetch_server_record(Entity.t, Server.id) ::
    map
    | nil
  def fetch_server_record(entity, server) do
    entity
    |> HackDatabaseInternal.get_entry_by_server_id(server)
    |> HackDatabaseInternal.select_for_presentation()
    |> Repo.one()
  end
end
