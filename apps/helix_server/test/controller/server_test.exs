defmodule Helix.Server.Controller.ServerTest do

  use ExUnit.Case, async: true

  alias HELL.TestHelper.Random
  alias Helix.Server.Controller.Server, as: ServerController
  alias Helix.Server.Model.Server
  alias Helix.Server.Model.ServerType
  alias Helix.Server.Repo

  @moduletag :integration

  # FIXME: add more tests

  # FIXME: use fatories instead
  defp generate_params(params \\ []) do
    params = :maps.from_list(params)

    defaults = %{
      server_type: Enum.random(ServerType.possible_types),
      poi_id: Random.pk(),
      motherboard_id: Random.pk()
    }

    Map.merge(defaults, params)
  end

  defp create_server(params \\ []) do
    params
    |> generate_params()
    |> Server.create_changeset()
    |> Repo.insert!()
  end

  describe "creating" do
    test "creates server of given type" do
      params = generate_params()
      assert {:ok, _} = ServerController.create(params)
    end

    test "fails with invalid server_type" do
      params = generate_params(server_type: Burette.Color.name())

      assert_raise(Ecto.ConstraintError, fn ->
        ServerController.create(params)
      end)

      refute Repo.get_by(Server, server_type: params.server_type)
    end
  end

  describe "fetching" do
    test "succeeds by id" do
      server = create_server()
      assert %Server{} = ServerController.fetch(server.server_id)
    end

    test "succeeds by poi_id" do
      server = create_server()
      assert %Server{} = ServerController.fetch_by_poi(server.poi_id)
    end

    test "fails when server doesn't exists" do
      refute ServerController.fetch(Random.pk())
    end

    test "fails when server with poi_id doesn't exists" do
      refute ServerController.fetch_by_poi(Random.pk())
    end
  end

  describe "finding" do
    test "succeeds by id list" do
      # FIXME: use Factory.insert_list instead
      server_list =
        for _ <- 0..4 do
          server = create_server()
          server.server_id
        end

      expected = Enum.sort(server_list)
      found =
        [id: server_list]
        |> ServerController.find()
        |> Enum.map(&(&1.server_id))
        |> Enum.sort()

      assert expected == found
    end

    test "succeeds by type" do
      server_type = Enum.random(ServerType.possible_types())

      # FIXME: use Factory.insert_list instead
      expected =
        for _ <- 0..4 do
          server = create_server(server_type: server_type)
          server.server_id
        end

      found =
        [type: server_type]
        |> ServerController.find()
        |> Enum.map(&(&1.server_id))

      assert Enum.all?(expected, &(&1 in found))
    end

    test "returns an empty list when no server is found by id" do
      # FIXME: use Factory.insert_list instead
      bogus = for _ <- 0..4, do: Random.pk()
      result = ServerController.find(id: bogus)
      assert Enum.empty?(result)
    end
  end

  test "deleting is idempotent" do
    server = create_server()

    assert Repo.get(Server, server.server_id)
    ServerController.delete(server.server_id)
    ServerController.delete(server.server_id)
    refute Repo.get(Server, server.server_id)
  end
end
