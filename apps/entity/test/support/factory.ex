defmodule Helix.Entity.Factory do

  use ExMachina.Ecto, repo: Helix.Entity.Repo

  alias HELL.PK
  alias HELL.TestHelper.Random
  alias Helix.Entity.Controller.EntityComponent, as: EntityComponentController
  alias Helix.Entity.Controller.EntityServer, as: EntityServerController
  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Model.EntityComponent
  alias Helix.Entity.Model.EntityServer

  def params(:entity) do
    entity_type = generate_entity_type()

    %{
      entity_id: generate_pk(entity_type),
      entity_type: entity_type
    }
  end

  def params(:entity_component) do
    entity = insert(:entity)

    %{
      entity: entity,
      entity_id: entity.entity_id,
      component_id: Random.pk()
    }
  end

  def params(:entity_server) do
    entity = insert(:entity)

    %{
      entity: entity,
      entity_id: entity.entity_id,
      server_id: Random.pk()
    }
  end

  def servers_for(entity) do
    servers = Enum.map(0..4, fn _ -> Random.pk() end)

    Enum.each(servers, fn server ->
      EntityServerController.create(entity, server)
    end)

    servers
  end

  def components_for(entity) do
    components = Enum.map(0..4, fn _ -> Random.pk() end)

    Enum.each(components, fn component ->
      EntityComponentController.create(entity, component)
    end)

    components
  end

  def entity_factory do
    entity_type = generate_entity_type()

    %Entity{
      entity_id: generate_pk(entity_type),
      entity_type: entity_type
    }
  end

  def entity_component_factory do
    %EntityComponent{
      entity: build(:entity),
      component_id: Random.pk()
    }
  end

  def entity_server_factory do
    %EntityServer{
      entity: build(:entity),
      server_id: Random.pk()
    }
  end

  def generate_entity_type,
    do: Enum.random(["account", "clan", "npc"])

  def generate_pk("account"),
    do: PK.generate([0x0000, 0x0000, 0x0000])
  def generate_pk(_),
    do: Random.pk()
end