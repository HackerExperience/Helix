defmodule Helix.Hardware.Internal.NetworkConnectionTest do

  use Helix.Test.IntegrationCase

  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Hardware.Internal.Motherboard, as: MotherboardInternal
  alias Helix.Hardware.Query.Motherboard, as: MotherboardQuery
  alias Helix.Hardware.Internal.NetworkConnection, as: NetworkConnectionInternal

  alias HELL.TestHelper.Setup
  alias Helix.Cache.Helper, as: CacheHelper
  alias Helix.Network.Helper, as: NetworkHelper

  setup do
    {server, account} = Setup.server()
    {:ok, account: account, server: server}
  end

  describe "update_ip/2" do
    test "updates to new ip", context do
      server_id = context.server.server_id
      new_ip = HELL.IPv4.autogenerate()

      cur_ip = ServerQuery.get_ip(server_id, NetworkHelper.internet_id)
      nc = NetworkConnectionInternal.fetch_by_nip(
        NetworkHelper.internet_id,
        cur_ip)
      NetworkConnectionInternal.update_ip(nc, new_ip)

      # StatePurgeQueue.sync()
      updated_ip = ServerQuery.get_ip(server_id, NetworkHelper.internet_id)

      refute cur_ip == updated_ip
      assert updated_ip == new_ip

      CacheHelper.sync_test()
    end

    test "won't update to an existing ip", context do
      server_id = context.server.server_id
      existing_ip = "1.2.3.4"

      cur_ip = ServerQuery.get_ip(server_id, NetworkHelper.internet_id)
      nc = NetworkConnectionInternal.fetch_by_nip(
        NetworkHelper.internet_id,
        cur_ip)

      {:error, _} = NetworkConnectionInternal.update_ip(nc, existing_ip)

      updated_ip = ServerQuery.get_ip(server_id, NetworkHelper.internet_id)

      assert updated_ip == cur_ip

      CacheHelper.sync_test()
    end
  end

  describe "fetch/1" do
    test "it fetches, just like phoebe", context do
      motherboard_id = context.server.motherboard_id

      motherboard = MotherboardQuery.fetch(motherboard_id)

      [nic] = MotherboardInternal.get_nics(motherboard)
      network_connection_id = nic.network_connection.network_connection_id

      nc = NetworkConnectionInternal.fetch(network_connection_id)
      assert nc == nic.network_connection
    end
  end

  describe "fetch_by_nip" do
    test "it works", context do
      server_id = context.server.server_id

      {:ok, [nip]} = CacheQuery.from_server_get_nips(server_id)

      nc = NetworkConnectionInternal.fetch_by_nip(nip.network_id, nip.ip)

      refute nc == nil
      assert nc.network_id == nip.network_id
      assert nc.ip == nip.ip

      CacheHelper.sync_test()
    end
  end
end
