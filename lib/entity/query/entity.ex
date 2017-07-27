defmodule Helix.Entity.Query.Entity do

  import Ecto.Query, only: [select: 3, where: 3]

  alias Helix.Account.Model.Account
  alias Helix.Server.Model.Server
  alias Helix.Entity.Internal.Entity, as: EntityInternal
  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Model.EntityServer
  alias Helix.Entity.Repo

  @spec fetch(Entity.id) ::
    Entity.t
    | nil
  @doc """
  Fetch an entity by it's id

  ### Example

      iex> fetch("aa:bb::cc12:dd34")
  """
  defdelegate fetch(id),
    to: EntityInternal

  @spec fetch_by_server(Server.id) ::
    Entity.t
    | nil
  @doc """
  Returns the Entity that owns `server` or nil if not owned

  ### Example

      iex> fetch_by_server("a::b")
      %Entity{}
  """
  defdelegate fetch_by_server(server),
    to: EntityInternal

  @spec get_servers_from_entity(Entity.t) ::
    [Server.id]
  @doc """
  Returns the ids of the servers owned by the entity

  ### Example

      iex> get_servers_from_entity(%Entity{})
      ["a::b", "f9f9:9090:1::494"]
  """
  def get_servers_from_entity(%Entity{entity_id: id}) do
    EntityServer
    |> select([s], s.server_id)
    # FIXME: this belongs to EntityServer.Query
    |> where([s], s.entity_id == ^id)
    |> Repo.all()
  end

  @spec get_entity_id(struct) ::
    HELL.PK.t
  @doc """
  Returns the ID of an entity or entity-equivalent record
  """
  def get_entity_id(entity) do
    # TODO: Use a protocol ?
    case entity do
      %Entity{entity_id: id} ->
        id
      %Account{account_id: id} ->
        id
    end
  end
end
