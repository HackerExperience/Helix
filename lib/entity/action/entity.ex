defmodule Helix.Entity.Action.Entity do

  alias Helix.Account.Model.Account
  alias Helix.Hardware.Model.Component
  alias Helix.Server.Model.Server
  alias Helix.Universe.NPC.Model.NPC
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
  def create_from_specialization(%NPC{npc_id: npc_id}) do
    params = %{
      entity_id: npc_id,
      entity_type: :npc
    }

    EntityInternal.create(params)
  end


  @spec delete(Entity.t) ::
    :ok
  @doc """
  Deletes input `entity`

  Alternatively accepts the entity id as input
  """
  defdelegate delete(entity),
    to: EntityInternal

  @spec link_component(Entity.t, Component.id) ::
    :ok
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

  @spec unlink_component(Component.id) ::
    :ok
  @doc """
  Unlink `component`, effectively removing the component ownership

  ### Example

      iex> unlink_component("1::2")
      :ok
  """
  defdelegate unlink_component(component),
    to: EntityInternal

  @spec link_server(Entity.t, Server.id) ::
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

  @spec unlink_server(Server.id) ::
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
