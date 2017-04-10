defmodule Helix.Server.Service.API.ServerTest do

  use Helix.Test.IntegrationCase

  alias HELL.TestHelper.Random
  alias Helix.Server.Model.Server
  alias Helix.Server.Repo
  alias Helix.Server.Service.API.Server, as: API

  alias Helix.Hardware.Factory, as: HardwareFactory
  alias Helix.Server.Factory

  describe "create/2" do
    test "succeeds with valid input" do
      assert {:ok, %Server{}} = API.create(:desktop)
    end

    test "fails when input is invalid" do
      assert {:error, cs} = API.create(:invalid)
      refute cs.valid?
    end
  end

  describe "fetch/1" do
    test "succeeds by id" do
      server = Factory.insert(:server)
      assert %Server{} = API.fetch(server.server_id)
    end

    test "fails when server doesn't exist" do
      refute API.fetch(Random.pk())
    end
  end

  describe "find/2" do
    test "succeeds by id list" do
      server_ids =
        3
        |> Factory.insert_list(:server)
        |> Enum.map(&(&1.server_id))
        |> Enum.sort()

      found_ids =
        [id: server_ids]
        |> API.find()
        |> Enum.map(&(&1.server_id))
        |> Enum.sort()

      assert server_ids == found_ids
    end

    test "succeeds by type" do
      type = Factory.random_server_type()

      server_ids =
        3
        |> Factory.insert_list(:server, server_type: type)
        |> Enum.map(&(&1.server_id))

      found_ids =
        [type: type]
        |> API.find()
        |> Enum.map(&(&1.server_id))

      assert Enum.all?(server_ids, &(&1 in found_ids))
    end

    test "returns an empty list when no server is found by id" do
      bogus = [Random.pk()]
      assert Enum.empty?(API.find(id: bogus))
    end
  end

  describe "attach/2" do
    test "succeeds with valid input" do
      server = Factory.insert(:server)
      mobo = HardwareFactory.insert(:motherboard)

      assert {:ok, %Server{}} = API.attach(server, mobo.motherboard_id)
    end

    test "fails when input is invalid" do
      server = Factory.insert(:server)

      assert {:error, cs} = API.attach(server, "invalid")
      refute cs.valid?
    end

    test "fails when given motherboard is already attached" do
      mobo = HardwareFactory.insert(:motherboard)
      server = Factory.insert(:server)

      Factory.insert(:server, motherboard_id: mobo.motherboard_id)

      result = API.attach(server, mobo.motherboard_id)
      assert {:error, cs} = result
      refute cs.valid?
    end

    test "fails when server already has a motherboard" do
      mobo1 = HardwareFactory.insert(:motherboard)
      server = Factory.insert(:server, motherboard_id: mobo1.motherboard_id)

      mobo2 = HardwareFactory.insert(:motherboard)
      result = API.attach(server, mobo2.motherboard_id)

      assert {:error, cs} = result
      refute cs.valid?
    end
  end

  describe "detach/1" do
    test "is idempotent" do
      mobo = HardwareFactory.insert(:motherboard)
      server = Factory.insert(:server, motherboard_id: mobo.motherboard_id)

      API.detach(server)
      API.detach(server)

      server = Repo.get(Server, server.server_id)
      refute server.motherboard_id
    end
  end
end
