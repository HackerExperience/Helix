defmodule Helix.Entity.Factory do

  use ExMachina.Ecto, repo: Helix.Entity.Repo

  alias HELL.TestHelper.Random
  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Model.EntityComponent
  alias Helix.Entity.Model.EntityServer
  alias Helix.Entity.Model.EntityType

  def entity_factory do
    entity_type = Enum.random(EntityType.possible_types())

    %Entity{
      entity_id: Random.pk(),
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
end
