defmodule Helix.Entity.Service.API.Entity do

  alias Helix.Account.Model.Account
  alias Helix.Entity.Controller.Entity, as: EntityController
  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Model.EntityServer
  alias Helix.Entity.Repo

  import Ecto.Query, only: [select: 3, where: 3]

  @spec create_from_specialization(struct) ::
    {:ok, Entity.t}
    | {:error, Ecto.Changeset.t}
  @doc """
  Creates an `Entity` from an input entity-compatible record

  ### Example

      iex> create_from_specialization(%Account{})
      {:ok, %Entity{}}
  """
  def create_from_specialization(%Account{account_id: account_id}) do
    params = %{
      entity_id: account_id,
      entity_type: :account
    }

    EntityController.create(params)
  end

  @spec fetch(HELL.PK.t) ::
    Entity.t
    | nil
  @doc """
  Fetch an entity by it's id

  ### Example

      iex> fetch("aa:bb::cc12:dd34")
  """
  def fetch(id) do
    EntityController.fetch(id)
  end

  @spec delete(Entity.t) ::
    :ok
  @doc """
  Deletes input `entity`

  Alternatively accepts the entity id as input
  """
  def delete(entity) do
    # TODO: Accept entity-equivalent structs
    EntityController.delete(entity)
  end

  @spec fetch_server_owner(HELL.PK.t) ::
    Entity.t
    | nil
  @doc """
  Returns the Entity that owns `server` or nil if not owned

  ### Example

      iex> fetch_server_owner("a::b")
      %Entity{}
  """
  def fetch_server_owner(server) do
    EntityController.fetch_server_owner(server)
  end

  @spec get_servers_from_entity(Entity.t) ::
    [HELL.PK.t]
  @doc """
  Returns the ids of the servers owned by the entity

  ### Example

      iex> get_servers_from_entity(%Entity{})
      ["a::b", "f9f9:9090:1::494"]
  """
  def get_servers_from_entity(%Entity{entity_id: id}) do
    EntityServer
    |> select([s], s.server_id)
    |> where([s], s.entity_id == ^id)
    |> Repo.all()
  end

  @spec link_component(Entity.t, HELL.PK.t) ::
    :ok
    | {:error, reason :: term}
  @doc """
  Links `component` to `entity` effectively making entity the owner of the
  component

  ### Example

      iex> link_component(%Entity{}, "1::2")
      :ok
  """
  def link_component(entity, component) do
    EntityController.link_component(entity, component)
  end

  @spec unlink_component(HELL.PK.t) ::
    :ok
    | {:error, reason :: term}
  @doc """
  Unlink `component`, effectively removing the component ownership

  ### Example

      iex> unlink_component("1::2")
      :ok
  """
  def unlink_component(component) do
    EntityController.unlink_component(component)
  end

  @spec link_server(Entity.t, HELL.PK.t) ::
    :ok
    | {:error, reason :: term}
  @doc """
  Link `server` to `entity` effectively making entity the owner of the server

  ### Example

      iex> link_server(%Entity{}, "a::b")
      :ok
  """
  def link_server(entity, server) do
    EntityController.link_server(entity, server)
  end

  @spec unlink_server(HELL.PK.t) ::
    :ok
    | {:error, reason :: term}
  @doc """
  Unlink `server`, effectively removing the server ownership

  ### Example

      iex> unlink_server("a::b")
      :ok
  """
  def unlink_server(server) do
    EntityController.unlink_server(server)
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
