defmodule Helix.Network.Internal.Network.ConnectionTest do

  use Helix.Test.Case.Integration

  alias Helix.Server.Internal.Motherboard, as: MotherboardInternal
  alias Helix.Network.Internal.Network, as: NetworkInternal

  alias HELL.TestHelper.Random
  alias Helix.Test.Server.Component.Setup, as: ComponentSetup
  alias Helix.Test.Server.Setup, as: ServerSetup
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
    test "creates a NC" do
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
      {new_nic, _} = ComponentSetup.component(type: :nic)

      assert {:ok, nc} = NetworkInternal.Connection.create(network, ip, nic)

      assert nc.nic_id == nic.component_id

      assert {:ok, new_nc} = NetworkInternal.Connection.update_nic(nc, new_nic)

      refute new_nc == nc
      assert new_nc.nic_id == new_nic.component_id
      assert new_nc.ip == nc.ip
    end
  end

  describe "update_ip/2" do
    test "modifies ip" do
      {server, _} = ServerSetup.server()

      [nic] =
        server.motherboard_id
        |> MotherboardInternal.fetch()
        |> MotherboardInternal.get_nics()

      nc = NetworkInternal.Connection.fetch_by_nic(nic)

      new_ip = Random.ipv4()
      assert {:ok, new_nc} = NetworkInternal.Connection.update_ip(nc, new_ip)

      refute new_nc.ip == nc.ip
      assert new_nc.ip == new_ip
      assert new_nc.nic_id == nc.nic_id
    end
  end

  describe "delete/1" do
    test "obliterates the NC" do
      network = NetworkHelper.internet()
      ip = Random.ipv4()
      {nic, _} = ComponentSetup.component(type: :nic)

      assert {:ok, nc} = NetworkInternal.Connection.create(network, ip, nic)

      # Exists
      assert NetworkInternal.Connection.fetch(network, ip)

      # Delete
      NetworkInternal.Connection.delete(nc)

      # No more
      refute NetworkInternal.Connection.fetch(network, ip)
    end
  end
end
