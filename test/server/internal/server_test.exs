defmodule Helix.Server.Internal.ServerTest do

  use Helix.Test.IntegrationCase

  alias HELL.TestHelper.Random
  alias Helix.Server.Internal.Server, as: ServerInternal
  alias Helix.Server.Model.Server
  alias Helix.Server.Repo

  alias Helix.Server.Factory

  # FIXME: add more tests

  describe "creating" do
    test "succeeds with valid server_type" do
      params = %{server_type: Factory.random_server_type()}
      assert {:ok, _} = ServerInternal.create(params)
    end

    test "fails with invalid server_type" do
      {:error, cs} = ServerInternal.create(%{server_type: :foobar})
      assert :server_type in Keyword.keys(cs.errors)
    end
  end

  describe "fetching" do
    test "succeeds by id" do
      server = Factory.insert(:server)
      assert %Server{} = ServerInternal.fetch(server.server_id)
    end

    test "fails when server doesn't exists" do
      refute ServerInternal.fetch(Random.pk())
    end
  end

  test "deleting is idempotent" do
    server = Factory.insert(:server)
    assert Repo.get(Server, server.server_id)

    ServerInternal.delete(server.server_id)
    ServerInternal.delete(server.server_id)

    refute Repo.get(Server, server.server_id)
  end
end
