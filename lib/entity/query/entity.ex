defmodule Helix.Entity.Query.Entity do

  alias Helix.Universe.NPC.Model.NPC
  alias Helix.Account.Model.Account
  alias Helix.Server.Model.Server
  alias Helix.Entity.Internal.Entity, as: EntityInternal
  alias Helix.Entity.Model.Entity
  alias Helix.Universe.NPC.Model.NPC

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

  @spec fetch_by_server(Server.t | Server.id) ::
    Entity.t
    | nil
  @doc """
  Returns the Entity that owns `server` or nil if not owned

  ### Example

      iex> fetch_by_server(%Server.ID{})
      %Entity{}

      iex> fetch_by_server(%Server{})
      %Entity{}
  """
  def fetch_by_server(%Server{server_id: server_id}),
    do: fetch_by_server(server_id)
  defdelegate fetch_by_server(server_id),
    to: EntityInternal

  @spec get_servers(Entity.t) ::
    [Server.id]
  @doc """
  Returns the ids of the servers owned by the entity

  ### Example

      iex> get_servers(%Entity{})
      [%Server.ID{}, %Server.ID{}]
  """
  defdelegate get_servers(entity),
    to: EntityInternal

  @spec get_entity_id(struct) ::
    Entity.id
  @doc """
  Returns the ID of an entity or entity-equivalent record
  """
  def get_entity_id(entity) do
    case entity do
      %Account{account_id: %Account.ID{id: id}} ->
        %Entity.ID{id: id}
      %Account.ID{id: id} ->
        %Entity.ID{id: id}
      %NPC{npc_id: %NPC.ID{id: id}} ->
        %Entity.ID{id: id}
      %NPC.ID{id: id} ->
        %Entity.ID{id: id}
      value ->
        Entity.ID.cast!(value)
    end
  end
end
