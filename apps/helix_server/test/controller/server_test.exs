defmodule Helix.Server.Controller.ServerTest do

  use ExUnit.Case, async: true

  alias HELL.TestHelper.Random
  alias Helix.Server.Controller.Server, as: ServerController
  alias Helix.Server.Model.Server
  alias Helix.Server.Model.ServerType
  alias Helix.Server.Repo

  @moduletag :integration

  setup_all do
    server_types = Repo.all(ServerType)
    {:ok, server_types: server_types}
  end

  setup context do
    server_type = Enum.random(context.server_types)
    {:ok, server_type: server_type.server_type}
  end

  defp generate_params(server_type) do
    %{server_type: server_type}
  end

  describe "server creating" do
    test "creates server of given type", context do
      params = generate_params(context.server_type)
      {:ok, server} = ServerController.create(params)
      {:ok, found_server} = ServerController.find(server.server_id)

      # created server includes given id
      assert params.server_type == server.server_type

      # find yields the same previously created server
      assert server.server_type == found_server.server_type
    end

    test "fails when server_type is invalid" do
      params = %{server_type: Burette.Color.name()}

      # assert that creating an server with invalid type raises Ecto.ConstraintError
      assert_raise(Ecto.ConstraintError, fn ->
        ServerController.create(params)
      end)

      # no server was created
      refute Repo.get_by(Server, server_type: params.server_type)
    end
  end

  describe "server fetching" do
    test "fetches existing server", context do
      params = generate_params(context.server_type)
      {:ok, server} = ServerController.create(params)

      # an server is found
      assert {:ok, found_server} = ServerController.find(server.server_id)

      # the server is identical to the created one
      assert server.server_id == found_server.server_id
    end

    test "fails when server doesn't exists" do
      assert {:error, :notfound} == ServerController.find(Random.pk())
    end
  end

  test "delete is idempotent", context do
    params = generate_params(context.server_type)
    {:ok, server} = ServerController.create(params)

    # server exists before deleting
    assert Repo.get_by(Server, server_id: server.server_id)

    :ok = ServerController.delete(server.server_id)
    :ok = ServerController.delete(server.server_id)

    # server was deleted
    refute Repo.get_by(Server, server_id: server.server_id)
  end
end