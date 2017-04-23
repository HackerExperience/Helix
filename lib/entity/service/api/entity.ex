defmodule Helix.Entity.Service.API.Entity do

  alias Helix.Account.Model.Account
  alias Helix.Entity.Controller.Entity, as: EntityController
  alias Helix.Entity.Model.Entity

  @spec create_from_specialization(struct) ::
    {:ok, Entity.t}
    | {:error, Ecto.Changeset.t}
  def create_from_specialization(%Account{account_id: account_id}) do
    params = %{
      entity_id: account_id,
      entity_type: :account
    }

    EntityController.create(params)
  end

  @spec fetch(HELL.PK.t) :: Entity.t | nil
  def fetch(id) do
    EntityController.fetch(id)
  end

  @spec delete(Entity.t) :: :ok
  @doc """
  Deletes input `entity`

  Alternatively accepts the entity id as input
  """
  def delete(entity) do
    # TODO: Accept entity-equivalent structs
    EntityController.delete(entity)
  end

  @spec fetch_server_owner(HELL.PK.t) :: Entity.t | nil
  def fetch_server_owner(server) do
    EntityController.fetch_server_owner(server)
  end

  @spec link_component(Entity.t, HELL.PK.t) :: :ok | {:error, reason :: term}
  def link_component(entity, component) do
    EntityController.link_component(entity, component)
  end

  @spec unlink_component(HELL.PK.t) :: :ok | {:error, reason :: term}
  def unlink_component(component) do
    EntityController.unlink_component(component)
  end

  @spec link_server(Entity.t, HELL.PK.t) :: :ok | {:error, reason :: term}
  def link_server(entity, server) do
    EntityController.link_server(entity, server)
  end

  @spec unlink_server(HELL.PK.t) :: :ok | {:error, reason :: term}
  def unlink_server(server) do
    EntityController.unlink_server(server)
  end

  @spec get_entity_id(struct) :: term
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
