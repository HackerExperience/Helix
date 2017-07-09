defmodule Helix.Entity.Action.Entity do

  alias Helix.Account.Model.Account
  alias Helix.Entity.Internal.Entity, as: EntityInternal
  alias Helix.Entity.Model.Entity

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

    EntityInternal.create(params)
  end

  @spec delete(Entity.t) ::
    :ok
  @doc """
  Deletes input `entity`

  Alternatively accepts the entity id as input
  """
  def delete(entity) do
    # TODO: Accept entity-equivalent structs
    EntityInternal.delete(entity)
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
    EntityInternal.link_component(entity, component)
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
    EntityInternal.unlink_component(component)
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
    EntityInternal.link_server(entity, server)
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
    EntityInternal.unlink_server(server)
  end
end
