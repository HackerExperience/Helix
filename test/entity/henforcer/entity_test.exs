defmodule Helix.Entity.Henforcer.EntityTest do

  use Helix.Test.Case.Integration

  import Helix.Test.Henforcer.Macros

  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Henforcer.Entity, as: EntityHenforcer

  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Entity.Setup, as: EntitySetup

  describe "entity_exists?/1" do
    test "accepts when entity exists" do
      {entity, _} = EntitySetup.entity()

      assert {true, relay} = EntityHenforcer.entity_exists?(entity.entity_id)
      assert relay.entity == entity

      assert_relay relay, [:entity]
    end

    test "rejects when entity doesnt exists" do
      assert {false, reason, _} =
        EntityHenforcer.entity_exists?(Entity.ID.generate())
      assert reason == {:entity, :not_found}
    end
  end

  describe "owns_server?" do
    test "accepts when entity owns server" do
      {server, %{entity: entity}} = ServerSetup.server()

      assert {true, relay} =
        EntityHenforcer.owns_server?(entity.entity_id, server.server_id)

      assert relay.server == server
      assert relay.entity == entity

      assert_relay relay, [:server, :entity]
    end

    test "rejects when entity does not own server" do
      {server, _} = ServerSetup.server()
      {entity, _} = EntitySetup.entity()

      assert {false, reason, _} =
        EntityHenforcer.owns_server?(entity.entity_id, server.server_id)

      assert reason == {:server, :not_belongs}
    end
  end
end
