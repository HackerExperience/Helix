defmodule Helix.Entity.Query.Entity do

  alias Helix.Account.Model.Account
  alias Helix.Server.Model.Server
  alias Helix.Entity.Internal.Entity, as: EntityInternal
  alias Helix.Entity.Model.Entity

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

      iex> fetch_by_server("a::b")
      %Entity{}
  """
  def fetch_by_server(%Server{server_id: server_id}),
    do: fetch_by_server(server_id)
  defdelegate fetch_by_server(server_id),
    to: EntityInternal

  @spec get_servers(Entity.t | Entity.id) ::
    [Server.id]
  @doc """
  Returns the ids of the servers owned by the entity

  ### Example

      iex> get_servers(%Entity{})
      ["a::b", "f9f9:9090:1::494"]
  """
  def get_servers(%Entity{entity_id: entity_id}),
    do: get_servers(entity_id)
  defdelegate get_servers(entity_id),
    to: EntityInternal

  @spec get_entity_id(struct) ::
    Entity.id
  @doc """
  Returns the ID of an entity or entity-equivalent record
  """
  def get_entity_id(entity) do
    case entity do
      %Entity{entity_id: id} ->
        id
      %Account{account_id: %Account.ID{id: id}} ->
        # HACK: entity specializations have their own ID but those ID's are 1:1
        #   to entity ids
        %Entity.ID{id: id}
    end
  end
end
