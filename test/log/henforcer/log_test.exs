defmodule Helix.Log.Henforcer.LogTest do

  use Helix.Test.Case.Integration

  import Helix.Test.Henforcer.Macros

  alias Helix.Log.Henforcer.Log, as: LogHenforcer

  alias Helix.Test.Server.Helper, as: ServerHelper
  alias Helix.Test.Log.Helper, as: LogHelper
  alias Helix.Test.Log.Setup, as: LogSetup

  describe "log_exists?/1" do
    test "accepts when log exists" do
      {log, _} = LogSetup.log()

      assert {true, relay} = LogHenforcer.log_exists?(log.log_id)

      assert_relay relay, [:log]
    end

    test "rejects when log doesn't exists" do
      assert {false, reason, _} = LogHenforcer.log_exists?(LogHelper.id())
      assert reason == {:log, :not_found}
    end
  end

  describe "belongs_to_server?/2" do
    test "accepts when log belongs to server" do
      {log, _} = LogSetup.log()

      assert {true, %{}} == LogHenforcer.belongs_to_server?(log, log.server_id)
    end

    test "rejects when log does not belong to server" do
      {fake_log, _} = LogSetup.fake_log()

      assert {false, reason, _} =
        LogHenforcer.belongs_to_server?(fake_log, ServerHelper.id())
      assert reason == {:log, :not_belongs}
    end
  end
end
