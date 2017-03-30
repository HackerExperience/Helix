defmodule Helix.Server.Service.API.ServerTest do

  use ExUnit.Case, async: true

  alias HELL.TestHelper.Random
  alias Helix.Server.Model.Server
  alias Helix.Server.Service.API.Server, as: API

  alias Helix.Hardware.Factory, as: HardwareFactory
  alias Helix.Server.Factory

  describe "create/3" do
    test "succeeds with valid input" do
      mobo = HardwareFactory.insert(:motherboard)
      params = %{
        server_type: "desktop",
        poi_id: Random.pk(),
        motherboard_id: mobo.motherboard_id
      }

      assert {:ok, %Server{}} = API.create(params)
    end

    test "returns changeset when input is invalid" do
      params = %{}
      assert {:error, %Ecto.Changeset{}} = API.create(params)

      params = %{
        server_type: "invalid",
        poi_id: "invalid",
        motherboard_id: "invalid"
      }

      assert {:error, %Ecto.Changeset{}} = API.create(params)
    end

    test "returns changeset when motherboard is already attached" do
      mobo = HardwareFactory.insert(:motherboard)
      params = %{server_type: "desktop", motherboard_id: mobo.motherboard_id}

      Factory.insert(:server, motherboard_id: mobo.motherboard_id)
      API.create(params)

      assert {:error, %Ecto.Changeset{}} = API.create(params)
    end
  end

  describe "fetch/1" do
    test "succeeds by id" do
      server = Factory.insert(:server)
      assert %Server{} = API.fetch(server.server_id)
    end

    test "fails when server with id doesn't exist" do
      refute API.fetch(Random.pk())
    end
  end

  describe "find/2" do
    test "succeeds by id list" do
      servers =
        3
        |> Factory.insert_list(:server)
        |> Enum.map(&(&.server_id))

      found = API.find(id: server_list)

      assert Enum.all?(found, &(&1.server_id in servers))
    end

    test "succeeds by type" do
      type = Factory.random_server_type()

      servers =
        3
        |> Factory.insert_list(:server, server_type: type)
        |> Enum.map(&(&.server_id))

      found =
        [type: server_type]
        |> API.find()
        |> Enum.map(&(&.server_id))

      assert Enum.all?(servers, &(&1 in found))
    end

    test "returns an empty list when no server is found by id" do
      bogus = [Random.pk()]
      assert Enum.empty?(ServerController.find(id: bogus))
    end

    test "returns an empty list when no server is found by type" do
      bogus = Random.string()
      assert Enum.empty?(ServerController.find(type: bogus))
    end
  end

  describe "attach/2" do
    test "succeeds with valid input" do
      server = Factory.insert(:server)
      mobo = HardwareFactory.insert(:motherboard)

      assert {:ok, %Server{}} = API.attach(server, mobo.motherboard_id)
    end

    test "returns changeset when input is invalid" do
      server = Factory.insert(:server)
      assert {:error, %Ecto.Changeset{}} = API.attach(server, "invalid")
    end

    test "returns changeset when given motherboard is already attached" do
      mobo = HardwareFactory.insert(:motherboard)
      server = Factory.insert(:server)

      Factory.insert(:server, motherboard_id: mobo.motherboard_id)

      result = API.attach(server, mobo.motherboard_id)
      assert {:error, %Ecto.Changeset{}} = result
    end

    test "returns atom when server already has a motherboard" do
      mobo1 = HardwareFactory.insert(:motherboard)
      mobo2 = HardwareFactory.insert(:motherboard)

      server = Factory.insert(:server, motherboard_id: mobo1.motherboard_id)

      result = API.attach(server, mobo2.motherboard_id)
      assert {:error, :motherboard_already_attached} = result
    end
  end

  describe "detach/1" do
    test "succeeds with valid input" do
      mobo = HardwareFactory.insert(:motherboard)
      server = Factory.insert(:server, motherboard_id: mobo.motherboard_id)

      assert {:ok, %Server{}} = API.detach(server)
    end

    test "is idempotent" do
      mobo = HardwareFactory.insert(:motherboard)
      server = Factory.insert(:server, motherboard_id: mobo.motherboard_id)

      assert {:ok, server} = API.detach(server)
      assert {:ok, %Server{}} = API.detach(server)
    end
  end
end
