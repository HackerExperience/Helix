defmodule Helix.Network.Internal.NetworkTest do

  use Helix.Test.Case.Integration

  alias Helix.Network.Model.Network
  alias Helix.Network.Internal.Network, as: NetworkInternal

  alias HELL.TestHelper.Random
  alias Helix.Test.Network.Setup, as: NetworkSetup

  describe "fetch/1" do
    test "returns the network" do
      {network, _} = NetworkSetup.network()

      entry = NetworkInternal.fetch(network.network_id)

      assert entry == network
    end

    test "returns empty when not found" do
      refute NetworkInternal.fetch(Network.ID.generate())
    end
  end

  describe "create/2" do
    test "creates the network" do
      name = Random.string(min: 5, max: 10)
      type = :lan

      assert {:ok, network} = NetworkInternal.create(name, type)

      assert network.name == name
      assert network.type == type
    end

    test "fails if invalid network type is specified" do
      assert {:error, changeset} = NetworkInternal.create("wat", :wat)
      assert :type in Keyword.keys(changeset.errors)
    end
  end

  describe "delete/1" do
    test "removes the network" do
      {network, _} = NetworkSetup.network()

      assert NetworkInternal.fetch(network.network_id)

      assert :ok == NetworkInternal.delete(network)

      refute NetworkInternal.fetch(network.network_id)
    end

    test "does not delete the Internet" do
      {internet, _} = NetworkSetup.network(type: :internet)

      assert NetworkInternal.fetch(internet.network_id)

      assert_raise RuntimeError, fn ->
        NetworkInternal.delete(internet)
      end
    end
  end
end
