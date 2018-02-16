defmodule Helix.Entity.Henforcer.EntityTest do

  use Helix.Test.Case.Integration

  import Helix.Test.Henforcer.Macros

  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Henforcer.Entity, as: EntityHenforcer

  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Network.Setup, as: NetworkSetup
  alias Helix.Test.Server.Component.Setup, as: ComponentSetup
  alias Helix.Test.Server.Helper, as: ServerHelper
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Universe.Bank.Setup, as: BankSetup
  alias Helix.Test.Entity.Setup, as: EntitySetup

  @internet_id NetworkHelper.internet_id()

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

  describe "owns_component?/3" do
    test "accepts when entity owns the component" do
      {server, %{entity: entity}} = ServerSetup.server()

      assert {true, relay} =
        EntityHenforcer.owns_component?(
          entity.entity_id, server.motherboard_id, nil
        )

      assert relay.component.component_id == server.motherboard_id
      assert relay.entity == entity
      assert length(relay.owned_components) >= 4

      assert_relay relay, [:component, :entity, :owned_components]
    end

    test "rejects when entity does not own the component" do
      {entity, _} = EntitySetup.entity()
      {component, _} = ComponentSetup.component()

      assert {false, reason, relay} =
        EntityHenforcer.owns_component?(entity, component, nil)

      assert reason == {:component, :not_belongs}

      assert_relay relay, [:component, :entity, :owned_components]
    end
  end

  describe "owns_nip?/4" do
    test "accepts when entity owns the nip" do
      {server, %{entity: entity}} = ServerSetup.server()

      %{ip: ip, network_id: network_id} = ServerHelper.get_nip(server)

      assert {true, relay} =
        EntityHenforcer.owns_nip?(entity.entity_id, network_id, ip, nil)

      assert relay.entity == entity
      assert relay.network_connection.network_id == network_id
      assert relay.network_connection.ip == ip
      # 2 NCs, one recently created + 1 from Campaign server
      assert length(relay.entity_network_connections) == 2

      assert_relay relay,
        [:entity, :network_connection, :entity_network_connections]
    end

    test "rejects when entity doesn't own the nip" do
      {entity, _} = EntitySetup.entity()

      assert {false, reason, _} =
        EntityHenforcer.owns_nip?(
          entity.entity_id, @internet_id, "1.2.3.4", nil
        )

      assert reason == {:network_connection, :not_belongs}
    end
  end

  describe "owns_bounce?/2" do
    test "accepts when entity is the owner of the bounce" do
      {entity, _} = EntitySetup.entity()
      {bounce, _} = NetworkSetup.Bounce.bounce(entity_id: entity.entity_id)

      assert {true, relay} =
        EntityHenforcer.owns_bounce?(entity.entity_id, bounce.bounce_id)

      assert relay.bounce == bounce
      assert relay.entity == entity
      assert_relay relay, [:bounce, :entity]
    end

    test "rejects when entity does not own the bounce" do
      {entity, _} = EntitySetup.entity()
      {bounce, _} = NetworkSetup.Bounce.bounce()

      assert {false, reason, _} =
        EntityHenforcer.owns_bounce?(entity.entity_id, bounce.bounce_id)

      assert reason == {:bounce, :not_belongs}
    end
  end

  describe "owns_bank_account?/2" do
    test "accepts when entity is the owner of the bank account" do
      {entity, _} = EntitySetup.entity()
      bank_acc = BankSetup.account!(owner_id: entity.entity_id)

      assert {true, relay} =
        EntityHenforcer.owns_bank_account?(entity.entity_id, bank_acc)

      assert relay.entity == entity
      assert relay.bank_account === bank_acc

      assert_relay relay, [:entity, :bank_account]
    end

    test "rejects when entity does not own the bank account" do
      {entity, _} = EntitySetup.entity()
      bank_acc = BankSetup.account!()

      assert {false, reason, _} =
        EntityHenforcer.owns_bank_account?(entity.entity_id, bank_acc)

      assert reason == {:bank_account, :not_belongs}
    end
  end
end
