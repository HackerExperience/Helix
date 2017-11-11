defmodule Helix.Server.Henforcer.ServerTest do

  use Helix.Test.Case.Integration

  import Helix.Test.Henforcer.Macros

  alias Helix.Server.Henforcer.Server, as: ServerHenforcer
  alias Helix.Server.Model.Server

  alias Helix.Test.Entity.Setup, as: EntitySetup
  alias Helix.Test.Server.Setup, as: ServerSetup

  describe "server_exists?/1" do
    test "accepts when server exists" do
      {server, _} = ServerSetup.server()

      assert {true, relay} = ServerHenforcer.server_exists?(server.server_id)

      assert_relay relay, [:server]
    end

    test "rejects when server doesn't exists" do
      server_id = Server.ID.generate()
      assert {false, reason, _} = ServerHenforcer.server_exists?(server_id)
      assert reason == {:server, :not_found}
    end
  end

  describe "server_assembled?" do
    test "accepts when server motherboard is assembled" do
      {server, _} = ServerSetup.server()

      assert {true, relay} = ServerHenforcer.server_assembled?(server.server_id)
      assert_relay relay, [:server]
    end

    test "rejects when server has no motherboard attached to it" do
      {server, _} = ServerSetup.server

      server = %{server| motherboard_id: nil}

      assert {false, reason, _} = ServerHenforcer.server_assembled?(server)
      assert reason == {:server, :not_assembled}
    end
  end

  describe "hostname_valid?/1" do
    test "accepts valid hostname" do
      hostname = "transltr"
      assert {true, relay} = ServerHenforcer.hostname_valid?(hostname)
      assert relay.hostname == hostname

      assert_relay relay, [:hostname]
    end

    test "rejects invalid hostname" do
      h1 = ""
      h2 = "^&*!?;."
      valid1 = "abcABC09.___--#@"

      assert {false, reason, _} = ServerHenforcer.hostname_valid?(h1)
      assert {false, _, _} = ServerHenforcer.hostname_valid?(h2)
      assert {true, _} = ServerHenforcer.hostname_valid?(valid1)

      assert reason == {:hostname, :invalid}
    end
  end

  describe "can_set_hostname?/3" do
    test "allows server owner to set hostname" do
      {server, %{entity: entity}} = ServerSetup.server()

      hostname = "Mainframe"

      assert {true, relay} =
        ServerHenforcer.can_set_hostname?(
          entity.entity_id, server.server_id, hostname
        )

      assert relay.hostname == hostname
      assert relay.entity == entity
      assert relay.server == server

      assert_relay relay, [:hostname, :entity, :server]
    end

    test "rejects a weirdo messing with my hostname" do
      {server, _} = ServerSetup.server()
      {weirdo, _} = EntitySetup.entity()

      assert {false, reason, _} =
        ServerHenforcer.can_set_hostname?(
          weirdo.entity_id, server.server_id, "wat"
        )

      assert reason == {:server, :not_belongs}
    end
  end
end
