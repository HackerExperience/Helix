defmodule Helix.Entity.Factory do

  use ExMachina.Ecto, repo: Helix.Entity.Repo

  alias HELL.PK
  alias HELL.TestHelper.Random
  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Model.EntityComponent
  alias Helix.Entity.Model.EntityServer

  @entity_types %{
    "account"                => Helix.Account.Model.Account,
    "clan"                   => Helix.Clan.Model.Clan,
    "npc"                    => Helix.NPC.Model.NPC
  }

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

  defp generate_entity_type,
    do: Enum.random(["account", "clan", "npc"])

  for {entity_type, module} <- @entity_types do
    defp generate_pk(unquote(entity_type)),
      do: PK.pk_for(unquote(module))
  end
end