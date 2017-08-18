defmodule Helix.Server.Action.ServerTest do

  use Helix.Test.Case.Integration

  alias Helix.Test.Cache.Helper, as: CacheHelper
  alias Helix.Server.Action.Server, as: ServerAction
  alias Helix.Server.Model.Server
  alias Helix.Server.Repo

  alias Helix.Test.Hardware.Factory, as: HardwareFactory
  alias Helix.Test.Server.Factory

  describe "create/2" do
    test "succeeds with valid input" do
      assert {:ok, %Server{}} = ServerAction.create(:desktop)
    end

    test "fails when input is invalid" do
      assert {:error, cs} = ServerAction.create(:invalid)
      refute cs.valid?
    end
  end

  describe "attach/2" do
    test "succeeds with valid input" do
      server = Factory.insert(:server)
      mobo = HardwareFactory.insert(:motherboard)

      assert {:ok, %Server{}} = ServerAction.attach(server, mobo.motherboard_id)

      CacheHelper.sync_test()
    end

    # Review: Deprecate: This test isn't useful.
    # If I pass any PK, it will attach the motherboard without verification
    # The verification (and this test) should be at the Public/Henforced level
    test "fails when input is invalid" do
      server = Factory.insert(:server)

      assert {:error, cs} = ServerAction.attach(server, "invalid")
      refute cs.valid?
    end

    test "fails when given motherboard is already attached" do
      mobo = HardwareFactory.insert(:motherboard)
      server = Factory.insert(:server)

      Factory.insert(:server, motherboard_id: mobo.motherboard_id)

      result = ServerAction.attach(server, mobo.motherboard_id)
      assert {:error, cs} = result
      refute cs.valid?

      CacheHelper.sync_test()
    end

    test "fails when server already has a motherboard" do
      mobo1 = HardwareFactory.insert(:motherboard)
      server = Factory.insert(:server, motherboard_id: mobo1.motherboard_id)

      mobo2 = HardwareFactory.insert(:motherboard)
      result = ServerAction.attach(server, mobo2.motherboard_id)

      assert {:error, cs} = result
      refute cs.valid?

      CacheHelper.sync_test()
    end
  end

  describe "detach/1" do
    test "is idempotent" do
      mobo = HardwareFactory.insert(:motherboard)
      server = Factory.insert(:server, motherboard_id: mobo.motherboard_id)

      ServerAction.detach(server)
      ServerAction.detach(server)

      server = Repo.get(Server, server.server_id)
      refute server.motherboard_id

      CacheHelper.sync_test()
    end
  end

  describe "delete/1" do
    test "removes the record from database" do
      server = Factory.insert(:server)

      assert Repo.get(Server, server.server_id)
      ServerAction.delete(server)
      refute Repo.get(Server, server.server_id)

      CacheHelper.sync_test()
    end
  end
end
