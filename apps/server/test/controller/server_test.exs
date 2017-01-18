defmodule Helix.Server.Controller.ServerTest do

  use ExUnit.Case, async: true

  alias HELL.PK
  alias HELL.TestHelper.Random, as: HRand
  alias Helix.Server.Repo
  alias Helix.Server.Controller.Server, as: ServerController
  alias Helix.Server.Model.ServerType

  @server_type HRand.string(min: 20)

  setup_all do
    %{server_type: @server_type}
    |> ServerType.create_changeset()
    |> Repo.insert!()

    :ok
  end

  setup do
    payload = %{server_type: @server_type}
    {:ok, payload: payload}
  end

  test "create/2", %{payload: payload} do
    assert {:ok, _} = ServerController.create(payload)
  end

  describe "find/1" do
    test "success", %{payload: payload} do
      {:ok, serv} = ServerController.create(payload)
      assert {:ok, serv} == ServerController.find(serv.server_id)
    end

    test "failure" do
      assert {:error, :notfound} == ServerController.find(PK.generate([]))
    end
  end

  describe "update/2" do
    test "change server location", %{payload: payload} do
      assert {:ok, server} = ServerController.create(payload)

      poi = PK.generate([])
      payload2 = %{poi_id: poi}
      assert {:ok, server} = ServerController.update(server.server_id, payload2)
      assert poi == to_string(server.poi_id)
    end

    test "change motherboard id", %{payload: payload} do
      assert {:ok, server} = ServerController.create(payload)

      mobo = PK.generate([])
      payload2 = %{motherboard_id: mobo}
      assert {:ok, server} = ServerController.update(server.server_id, payload2)
      assert mobo == to_string(server.motherboard_id)
    end

    test "server not found" do
      assert {:error, :notfound} == ServerController.update(PK.generate([]), %{})
    end
  end

  test "delete/1 idempotency", %{payload: payload} do
    {:ok, serv} = ServerController.create(payload)
    assert :ok == ServerController.delete(serv.server_id)
    assert :ok == ServerController.delete(serv.server_id)
    assert {:error, :notfound} == ServerController.find(serv.server_id)
  end
end