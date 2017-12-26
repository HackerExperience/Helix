defmodule Helix.Entity.Action.Entity do

  alias Helix.Account.Model.Account
  alias Helix.Server.Model.Component
  alias Helix.Server.Model.Server
  alias Helix.Universe.NPC.Model.NPC
  alias Helix.Entity.Internal.Entity, as: EntityInternal
  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Model.EntityComponent
  alias Helix.Entity.Query.Entity, as: EntityQuery

  alias Helix.Entity.Event.Entity.Created, as: EntityCreatedEvent

  @spec create_from_specialization(struct) ::
    {:ok, Entity.t, [EntityCreatedEvent.t]}
    | {:error, :internal}
  @doc """
  Creates an `Entity` from an input entity-compatible record

  ### Example

      iex> create_from_specialization(%Account{})
      {:ok, %Entity{}}
  """
  def create_from_specialization(account = %Account{}),
    do: create(account, :account)
  def create_from_specialization(npc = %NPC{}),
    do: create(npc, :npc)

  defp create(source, type) do
    params =
      %{
        entity_id: EntityQuery.get_entity_id(source),
        entity_type: type
      }

    case EntityInternal.create(params) do
      {:ok, entity} ->
        event = EntityCreatedEvent.new(entity, source)
        {:ok, entity, [event]}

      {:error, _} ->
        {:error, :internal}
    end
  end

  @spec delete(Entity.t) ::
    :ok
  @doc """
  Deletes input `entity`
  """
  defdelegate delete(entity),
    to: EntityInternal

  @spec link_component(Entity.t, Component.idt) ::
    {:ok, EntityComponent.t}
    | {:error, Ecto.Changeset.t}
  @doc """
  Links `component` to `entity` effectively making entity the owner of the
  component

  ### Example

      iex> link_component(%Entity{}, "1::2")
      :ok
  """
  defdelegate link_component(entity, component),
    to: EntityInternal

  @spec unlink_component(Component.idt) ::
    :ok
  @doc """
  Unlink `component`, effectively removing the component ownership

  ### Example

      iex> unlink_component("1::2")
      :ok
  """
  defdelegate unlink_component(component),
    to: EntityInternal

  @spec link_server(Entity.t, Server.idt) ::
    :ok
    | {:error, Ecto.Changeset.t}
  @doc """
  Link `server` to `entity` effectively making entity the owner of the server

  ### Example

      iex> link_server(%Entity{}, "a::b")
      :ok
  """
  defdelegate link_server(entity, server),
  to: EntityInternal

  @spec unlink_server(Server.idt) ::
    :ok
  @doc """
  Unlink `server`, effectively removing the server ownership

  ### Example

      iex> unlink_server("a::b")
      :ok
  """
  defdelegate unlink_server(server),
    to: EntityInternal
end
