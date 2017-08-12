defmodule Helix.Server.Query.ServerTest do

  use Helix.Test.IntegrationCase

  alias Helix.Hardware.Model.Component
  alias Helix.Server.Action.Server, as: ServerAction
  alias Helix.Server.Model.Server
  alias Helix.Server.Query.Server, as: ServerQuery

  alias HELL.TestHelper.Setup
  alias Helix.Cache.Helper, as: CacheHelper
  alias Helix.Network.Helper, as: NetworkHelper
  alias Helix.Server.Factory

  describe "fetch/1" do
    test "succeeds by id" do
      server = Factory.insert(:server)
      assert %Server{} = ServerQuery.fetch(server.server_id)
    end

    test "fails when server doesn't exist" do
      refute ServerQuery.fetch(Server.ID.generate())
    end
  end

  describe "fetch_by_motherboard/1" do
    test "returns the server that mounts the motherboard" do
      server = Factory.insert(:server)
      motherboard = Component.ID.generate()

      ServerAction.attach(server, motherboard)

      fetched = ServerQuery.fetch_by_motherboard(motherboard)
      assert server.server_id == fetched.server_id

      CacheHelper.sync_test()
    end
  end

  describe "get_ip" do
    test "gets ip" do
      {server, _} = Setup.server()

      ip = ServerQuery.get_ip(server.server_id, NetworkHelper.internet_id())

      assert ip
    end
  end
end
