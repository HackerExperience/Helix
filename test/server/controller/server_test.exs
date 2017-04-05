defmodule Helix.Server.Controller.ServerTest do

  use ExUnit.Case, async: true

  alias HELL.TestHelper.Random
  alias Helix.Server.Controller.Server, as: ServerController
  alias Helix.Server.Model.Server
  alias Helix.Server.Model.ServerType
  alias Helix.Server.Repo

  alias Helix.Server.Factory

  @moduletag :integration

  # FIXME: add more tests

  describe "creating" do
    test "succeeds with valid server_type" do
      params = %{server_type: Factory.random_server_type()}
      assert {:ok, _} = ServerController.create(params)
    end

    test "fails with invalid server_type" do
      {:error, cs} = ServerController.create(%{server_type: :foobar})
      assert :server_type in Keyword.keys(cs.errors)
    end
  end

  describe "fetching" do
    test "succeeds by id" do
      server = Factory.insert(:server)
      assert %Server{} = ServerController.fetch(server.server_id)
    end

    test "fails when server doesn't exists" do
      refute ServerController.fetch(Random.pk())
    end
  end

  describe "finding" do
    test "succeeds by id list" do
      server_list =
        3
        |> Factory.insert_list(:server)
        |> Enum.map(&(&1.server_id))
        |> Enum.sort()

      found =
        [id: server_list]
        |> ServerController.find()
        |> Enum.map(&(&1.server_id))
        |> Enum.sort()

      assert server_list == found
    end

    test "succeeds by type" do
      server_type = Enum.random(ServerType.possible_types())
      expected =
        3
        |> Factory.insert_list(:server, server_type: server_type)
        |> Enum.map(&(&1.server_id))

      found =
        [type: server_type]
        |> ServerController.find()
        |> Enum.map(&(&1.server_id))

      assert Enum.all?(expected, &(&1 in found))
    end

    test "returns an empty list when no server is found by id" do
      bogus =
        3
        |> Factory.build_list(:server)
        |> Enum.map(&(&1.server_id))

      result = ServerController.find(id: bogus)
      assert Enum.empty?(result)
    end
  end

  test "deleting is idempotent" do
    server = Factory.insert(:server)
    assert Repo.get(Server, server.server_id)

    ServerController.delete(server.server_id)
    ServerController.delete(server.server_id)

    refute Repo.get(Server, server.server_id)
  end
end
