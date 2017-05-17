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

  describe "fetch_by_motherboard/1" do
    test "returns the server that mounts the motherboard" do
      server = Factory.insert(:server)
      motherboard = Random.pk()

      API.attach(server, motherboard)

      fetched = API.fetch_by_motherboard(motherboard)
      assert server.server_id == fetched.server_id
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

  describe "delete/1" do
    test "removes the record from database" do
      server = Factory.insert(:server)

      assert Repo.get(Server, server.server_id)
      API.delete(server)
      refute Repo.get(Server, server.server_id)
    end

    @tag :pending
    test "is idempotent" do
      server = Factory.insert(:server)

      assert API.delete(server)
      assert API.delete(server)
      assert API.delete(server)
    end
  end
end
