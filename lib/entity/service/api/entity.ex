defmodule Helix.Entity.Service.API.Entity do

  alias Helix.Entity.Controller.Entity, as: EntityController
  alias Helix.Entity.Model.Entity

  # Note that Entity API has no create function because it should be created
  # through reactions to events

  @spec fetch(HELL.PK.t) :: Entity.t | nil
  def fetch(id) do
    EntityController.fetch(id)
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
end
