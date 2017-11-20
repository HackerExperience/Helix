defmodule Helix.Network.Internal.Network.ConnectionTest do

  use Helix.Test.Case.Integration

  alias Helix.Network.Internal.Network, as: NetworkInternal

  alias HELL.TestHelper.Random
  alias Helix.Test.Server.Component.Setup, as: ComponentSetup
  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Network.Setup, as: NetworkSetup

  describe "fetch/2" do
    test "returns the Network.Connection" do
      {nc, _} = NetworkSetup.Connection.connection(real_nic: true)

      # Generated an NC with NIC
      assert nc.nic_id

      entry = NetworkInternal.Connection.fetch(nc.network_id, nc.ip)

      assert entry == nc
    end
  end

  describe "fetch_by_nic/1" do
    test "returns the Network.Connection" do
      {nc, %{nic: nic}} = NetworkSetup.Connection.connection(real_nic: true)

      entry = NetworkInternal.Connection.fetch_by_nic(nic)

      assert entry == nc
    end
  end

  describe "create/3" do
    test "creates a NC (without nic)" do
      network = NetworkHelper.internet()
      ip = Random.ipv4()

      assert {:ok, nc} = NetworkInternal.Connection.create(network, ip)

      assert nc.network_id == network.network_id
      assert nc.ip == ip
      refute nc.nic_id
    end

    test "creates a NC (with nic)" do
      network = NetworkHelper.internet()
      ip = Random.ipv4()
      {nic, _} = ComponentSetup.component(type: :nic)

      assert {:ok, nc} = NetworkInternal.Connection.create(network, ip, nic)

      assert nc.network_id == network.network_id
      assert nc.ip == ip
      assert nc.nic_id == nic.component_id
    end
  end

  describe "update_nic/2" do
    test "modifies nic" do
      network = NetworkHelper.internet()
      ip = Random.ipv4()
      {nic, _} = ComponentSetup.component(type: :nic)

      assert {:ok, nc} = NetworkInternal.Connection.create(network, ip)

      assert {:ok, new_nc} = NetworkInternal.Connection.update_nic(nc, nic)

      refute new_nc == nc
      assert new_nc.nic_id == nic.component_id
    end
  end
end
