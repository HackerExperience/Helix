defmodule Helix.Server.Henforcer.ServerTest do

  use Helix.Test.IntegrationCase

  alias Helix.Server.Internal.Server, as: ServerInternal
  alias Helix.Server.Henforcer.Server, as: Henforcer
  alias Helix.Server.Model.Server

  alias Helix.Cache.Helper, as: CacheHelper
  alias Helix.Hardware.Factory, as: HardwareFactory
  alias Helix.Server.Factory

  describe "exists?/1" do
    test "returns true when server exists" do
      server = Factory.insert(:server)

      assert Henforcer.exists?(server.server_id)
    end

    test "returns false when server doesn't exists" do
      # well, i personally find those test descriptions a litte too redundant

      refute Henforcer.exists?(Server.ID.generate())
    end
  end

  describe "functioning?/1" do
    # TODO: link components on motherboard otherwise it fails
    @tag :pending
    test "returns true when server has motherboard attached" do
      server = Factory.insert(:server)
      motherboard = HardwareFactory.insert(:motherboard)
      ServerInternal.attach(server, motherboard.motherboard_id)

      assert Henforcer.functioning?(server.server_id)

      CacheHelper.sync_test()
    end

    @tag :pending
    test "returns false when motherboard doesn't have atleast cpu, hdd and ram"

    test "returns false if server has no motherboard attached" do
      server = Factory.insert(:server)

      refute Henforcer.functioning?(server.server_id)
    end

    test "returns false if server doesn't exists" do
      refute Henforcer.functioning?(Server.ID.generate())
    end
  end
end
