defmodule Helix.Entity.Factory do

  use ExMachina.Ecto, repo: Helix.Entity.Repo

  alias HELL.PK
  alias HELL.TestHelper.Random
  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Model.EntityComponent
  alias Helix.Entity.Model.EntityServer

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