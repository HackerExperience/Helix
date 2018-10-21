defmodule Helix.Log.Henforcer.Log.RecoverTest do

  use Helix.Test.Case.Integration

  import Helix.Test.Henforcer.Macros

  alias Helix.Log.Henforcer.Log.Recover, as: LogRecoverHenforcer

  alias Helix.Test.Server.Helper, as: ServerHelper
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Software.Setup, as: SoftwareSetup
  alias Helix.Test.Log.Setup, as: LogSetup

  describe "can_recover_custom?/3" do
    test "accepts when everything is OK" do
      {log, _} = LogSetup.log()

      gateway = ServerSetup.server!()
      recover = SoftwareSetup.log_recover!(server_id: gateway.server_id)

      assert {true, relay} =
        LogRecoverHenforcer.can_recover_custom?(
          log.log_id, gateway.server_id, log.server_id
        )

      assert_relay relay, [:log, :recover, :gateway]

      assert relay.log.log_id == log.log_id
      assert relay.gateway == gateway
      assert relay.recover == recover
    end

    test "rejects when player does not have a LogRecover software" do
      {log, _} = LogSetup.log()
      gateway = ServerSetup.server!()

      assert {false, reason, _} =
        LogRecoverHenforcer.can_recover_custom?(
          log.log_id, gateway.server_id, log.server_id
        )

      assert reason == {:recover, :not_found}
    end

    test "rejects when log does not belong to the given target (server)" do
      {log, _} = LogSetup.log()

      gateway = ServerSetup.server!()
      SoftwareSetup.log_recover(server_id: gateway.server_id)

      assert {false, reason, _} =
        LogRecoverHenforcer.can_recover_custom?(
          log.log_id, gateway.server_id, ServerHelper.id()
        )

      assert reason == {:log, :not_belongs}
    end
  end

  describe "can_recover_global?/1" do
    test "accepts when everything is ok" do
      gateway = ServerSetup.server!()
      recover = SoftwareSetup.log_recover!(server_id: gateway.server_id)

      assert {true, relay} =
        LogRecoverHenforcer.can_recover_global?(gateway.server_id)

      assert_relay relay, [:gateway, :recover]

      assert relay.gateway == gateway
      assert relay.recover == recover
    end

    test "rejects when player does not have a LogRecover" do
      gateway = ServerSetup.server!()

      assert {false, reason, _} =
        LogRecoverHenforcer.can_recover_global?(gateway.server_id)
      assert reason == {:recover, :not_found}
    end
  end
end
