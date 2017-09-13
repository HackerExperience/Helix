defmodule Helix.Server.Query.ServerTest do

  use Helix.Test.Case.Integration

  alias Helix.Server.Model.Server
  alias Helix.Server.Query.Server, as: ServerQuery

  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Cache.Helper, as: CacheHelper
  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Server.Factory

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
      {server, _} = ServerSetup.server()

      fetched = ServerQuery.fetch_by_motherboard(server.motherboard_id)
      assert server.server_id == fetched.server_id

      CacheHelper.sync_test()
    end
  end

  describe "get_ip/2" do
    test "returns server IP" do
      {server, _} = ServerSetup.server()

      assert ServerQuery.get_ip(server.server_id, NetworkHelper.internet_id())
    end
  end
end
