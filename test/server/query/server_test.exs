defmodule Helix.Server.Query.ServerTest do

  use Helix.Test.Case.Integration

  alias Helix.Server.Model.Server
  alias Helix.Server.Query.Server, as: ServerQuery

  alias Helix.Test.Server.Helper, as: ServerHelper
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Cache.Helper, as: CacheHelper
  alias Helix.Test.Network.Helper, as: NetworkHelper

  describe "fetch/1" do
    test "succeeds by id" do
      {server, _} = ServerSetup.server()
      assert %Server{} = ServerQuery.fetch(server.server_id)
    end

    test "fails when server doesn't exist" do
      refute ServerQuery.fetch(ServerHelper.id())
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

  describe "get_password/1" do
    test "correct password is returned (passing struct)" do
      {server, _} = ServerSetup.fake_server()

      assert {:ok, password} = ServerQuery.get_password(server)
      assert password == server.password
    end

    test "correct password is returned (passing ID)" do
      {server, _} = ServerSetup.server()

      assert {:ok, password} = ServerQuery.get_password(server.server_id)
      assert password == server.password
    end

    test "with non-existing server" do
      fake_server_id = ServerHelper.id()

      assert {:error, reason} = ServerQuery.get_password(fake_server_id)
      assert reason == {:server, :notfound}
    end
  end
end
