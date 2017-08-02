defmodule Helix.Server.Query.ServerTest do

  use Helix.Test.IntegrationCase

  alias HELL.TestHelper.Random
  alias Helix.Server.Action.Server, as: ServerAction
  alias Helix.Server.Model.Server
  alias Helix.Server.Query.Server, as: ServerQuery

  alias Helix.Cache.Helper, as: CacheHelper
  alias Helix.Server.Factory

  describe "fetch/1" do
    test "succeeds by id" do
      server = Factory.insert(:server)
      assert %Server{} = ServerQuery.fetch(server.server_id)
    end

    test "fails when server doesn't exist" do
      refute ServerQuery.fetch(Random.pk())
    end
  end

  describe "fetch_by_motherboard/1" do
    test "returns the server that mounts the motherboard" do
      server = Factory.insert(:server)
      motherboard = Random.pk()

      ServerAction.attach(server, motherboard)

      fetched = ServerQuery.fetch_by_motherboard(motherboard)
      assert server.server_id == fetched.server_id

      CacheHelper.sync_test()
    end
  end
end
