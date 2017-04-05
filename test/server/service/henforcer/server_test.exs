defmodule Helix.Server.Service.Henforcer.ServerTest do

  use ExUnit.Case, async: true

  alias HELL.TestHelper.Random
  alias Helix.Server.Controller.Server, as: ServerController
  alias Helix.Server.Service.Henforcer.Server, as: Henforcer

  alias Helix.Server.Factory
  alias Helix.Hardware.Factory, as: HardwareFactory

  describe "server_exists?/1" do
    test "returns true when server exists" do
      server = Factory.insert(:server)

      assert Henforcer.server_exists?(server.server_id)
    end

    test "returns false when server doesn't exists" do
      # well, i personally find those test descriptions a litte too redundant

      refute Henforcer.server_exists?(Random.pk())
    end
  end

  describe "server_assembled?/1" do
    test "returns true when server has motherboard attached" do
      server = Factory.insert(:server)
      motherboard = HardwareFactory.insert(:motherboard)
      ServerController.attach(server, motherboard.motherboard_id)

      assert Henforcer.server_assembled?(server.server_id)
    end

    test "returns false if server has no motherboard attached" do
      server = Factory.insert(:server)

      refute Henforcer.server_assembled?(server.server_id)
    end

    test "returns false if server doesn't exists" do
      refute Henforcer.server_assembled?(Random.pk())
    end
  end
end
