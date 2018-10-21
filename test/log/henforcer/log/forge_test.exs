defmodule Helix.Log.Henforcer.Log.ForgeTest do

  use Helix.Test.Case.Integration

  import Helix.Test.Henforcer.Macros

  alias Helix.Log.Henforcer.Log.Forge, as: LogForgeHenforcer

  alias Helix.Test.Server.Helper, as: ServerHelper
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Software.Setup, as: SoftwareSetup
  alias Helix.Test.Log.Setup, as: LogSetup

  describe "can_edit?/3" do
    test "accepts when everything is OK" do
      {log, _} = LogSetup.log()

      gateway = ServerSetup.server!()
      forger = SoftwareSetup.log_forger!(server_id: gateway.server_id)

      assert {true, relay} =
        LogForgeHenforcer.can_edit?(
          log.log_id, gateway.server_id, log.server_id
        )

      assert_relay relay, [:log, :forger, :gateway]

      assert relay.log.log_id == log.log_id
      assert relay.gateway == gateway
      assert relay.forger == forger
    end

    test "rejects when player does not have a LogForger software" do
      {log, _} = LogSetup.log()
      gateway = ServerSetup.server!()

      assert {false, reason, _} =
        LogForgeHenforcer.can_edit?(
          log.log_id, gateway.server_id, log.server_id
        )

      assert reason == {:forger, :not_found}
    end

    test "rejects when log does not belong to the given target (server)" do
      {log, _} = LogSetup.log()

      gateway = ServerSetup.server!()
      SoftwareSetup.log_forger(server_id: gateway.server_id)

      assert {false, reason, _} =
        LogForgeHenforcer.can_edit?(
          log.log_id, gateway.server_id, ServerHelper.id()
        )

      assert reason == {:log, :not_belongs}
    end
  end

  describe "can_create?/1" do
    test "accepts when everything is ok" do
      gateway = ServerSetup.server!()
      forger = SoftwareSetup.log_forger!(server_id: gateway.server_id)

      assert {true, relay} = LogForgeHenforcer.can_create?(gateway.server_id)

      assert_relay relay, [:gateway, :forger]

      assert relay.gateway == gateway
      assert relay.forger == forger
    end

    test "rejects when player does not have a LogForger" do
      gateway = ServerSetup.server!()

      assert {false, reason, _} =
        LogForgeHenforcer.can_create?(gateway.server_id)
      assert reason == {:forger, :not_found}
    end
  end
end
