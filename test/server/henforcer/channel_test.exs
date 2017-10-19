defmodule Helix.Server.Henforcer.ChannelTest do

  use Helix.Test.Case.Integration

  import Helix.Test.Henforcer.Macros

  alias Helix.Server.Henforcer.Channel, as: ChannelHenforcer

  alias Helix.Test.Entity.Setup, as: EntitySetup
  alias Helix.Test.Server.Setup, as: ServerSetup

  describe "local_join_allowed?/2" do
    test "accepts when everything is ok" do
      {server, %{entity: entity}} = ServerSetup.server()

      assert {true, relay} =
        ChannelHenforcer.local_join_allowed?(entity.entity_id, server.server_id)
      assert_relay relay, [:server, :entity]
    end

    test "rejects when entity does not own the server" do
      {server, _} = ServerSetup.server()
      {entity, _} = EntitySetup.entity()

      assert {false, reason, _} =
        ChannelHenforcer.local_join_allowed?(entity.entity_id, server.server_id)
      assert reason == {:server, :not_belongs}
    end
  end

  describe "remote_join_allowed?/4" do
    test "accepts when everything is ok" do
      {gateway, %{entity: entity}} = ServerSetup.server()
      {destination, _} = ServerSetup.server()

      assert {true, relay} =
        ChannelHenforcer.remote_join_allowed?(
          entity.entity_id,
          gateway.server_id,
          destination.server_id,
          destination.password
        )

      assert_relay relay, [:destination, :gateway, :entity]
    end

    test "rejects when password is invalid" do
      {gateway, %{entity: entity}} = ServerSetup.server()
      {destination, _} = ServerSetup.server()

      assert {false, reason, _} =
        ChannelHenforcer.remote_join_allowed?(
          entity.entity_id,
          gateway.server_id,
          destination.server_id,
          gateway.password  # Using gateway password, which is incorrect!
        )

      assert reason == {:password, :invalid}
    end

    test "rejects when entity does not own gateway" do
      {gateway, _} = ServerSetup.server()
      {destination, %{entity: bad_entity}} = ServerSetup.server()

      assert {false, reason, _} =
        ChannelHenforcer.remote_join_allowed?(
          bad_entity.entity_id,
          gateway.server_id,
          destination.server_id,
          destination.password
        )

      assert reason == {:server, :not_belongs}
    end
  end
end
