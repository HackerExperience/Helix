defmodule Helix.Cache.Integration.Network.NetworkConnectionTest do

  use Helix.Test.Case.Integration

  import Helix.Test.Case.Cache
  import Helix.Test.Case.ID

  alias Helix.Network.Internal.Network, as: NetworkInternal
  alias Helix.Server.Query.Component, as: ComponentQuery
  alias Helix.Cache.Internal.Builder, as: BuilderInternal
  alias Helix.Cache.Internal.Cache, as: CacheInternal
  alias Helix.Cache.Internal.Populate, as: PopulateInternal
  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Cache.State.PurgeQueue, as: StatePurgeQueue

  alias Helix.Test.Cache.Helper, as: CacheHelper

  setup do
    CacheHelper.cache_context()
  end

  describe "network connection actions" do
    test "changing ip", context do
      server_id = context.server.server_id

      {:ok, server} = PopulateInternal.populate(:by_server, server_id)

      nip = Enum.random(server.networks)
      nc = NetworkInternal.Connection.fetch(nip.network_id, nip.ip)
      new_ip = HELL.IPv4.autogenerate()

      refute StatePurgeQueue.lookup(:server, server_id)
      refute StatePurgeQueue.lookup(:network, {nip.network_id, nip.ip})

      {:ok, _} = NetworkInternal.Connection.update_ip(nc, new_ip)

      assert StatePurgeQueue.lookup(:server, server_id)
      nip_args1 = {to_string(nip.network_id), nip.ip}
      nip_args2 = {to_string(nip.network_id), new_ip}
      assert StatePurgeQueue.lookup(:network, nip_args1)
      assert StatePurgeQueue.lookup(:network, nip_args2)
      assert StatePurgeQueue.lookup(:storage, Enum.random(server.storages))

      # Not on the cache yet
      {:ok, server2} = CacheQuery.from_server_get_all(server_id)
      nip2 = Enum.random(server2.networks)
      assert nip2 == %{network_id: nip.network_id, ip: new_ip}

      {:error, reason} = CacheQuery.from_nip_get_server(nip.network_id, nip.ip)
      assert reason == {:nip, :notfound}

      {:ok, server3} = CacheQuery.from_nip_get_server(nip.network_id, new_ip)
      assert_id server3, server_id

      StatePurgeQueue.sync()

      # Ensure it's on cache
      assert_hit CacheInternal.direct_query(:server, server_id)

      # And returns correct data
      {:ok, server4} = CacheQuery.from_server_get_all(server_id)
      assert_id server4.networks, server2.networks

      CacheHelper.sync_test()
    end

    test "changing ip (cold)", context do
      server_id = context.server.server_id

      {:ok, server} = BuilderInternal.by_server(server_id)

      nip = Enum.random(server.networks)
      nc = NetworkInternal.Connection.fetch(nip.network_id, nip.ip)
      new_ip = HELL.IPv4.autogenerate()

      refute StatePurgeQueue.lookup(:server, server_id)
      refute StatePurgeQueue.lookup(:network, {nip.network_id, nip.ip})

      {:ok, _} = NetworkInternal.Connection.update_ip(nc, new_ip)

      assert StatePurgeQueue.lookup(:network, {nip.network_id, nip.ip})
      assert StatePurgeQueue.lookup(:network, {nip.network_id, new_ip})
      refute StatePurgeQueue.lookup(:server, server_id)
      refute StatePurgeQueue.lookup(:storage, Enum.random(server.storages))

      CacheHelper.sync_test()
    end

    test "changing NIC", context do
      server_id = context.server.server_id

      {:ok, server} = PopulateInternal.populate(:by_server, server_id)

      refute Enum.empty?(server.networks)
      nip = List.first(server.networks)
      nc = NetworkInternal.Connection.fetch(nip.network_id, nip.ip)
      nic = ComponentQuery.fetch(nc.nic_id)

      assert_hit CacheInternal.direct_query(:server, server_id)

      # Nothing scheduled to purge
      refute StatePurgeQueue.lookup(:server, server_id)
      refute StatePurgeQueue.lookup(:network, {nip.network_id, nip.ip})

      {:ok, nc} = NetworkInternal.Connection.update_nic(nc, nil)

      assert StatePurgeQueue.lookup(:server, server_id)
      nip_args = {to_string(nip.network_id), nip.ip}
      assert StatePurgeQueue.lookup(:network, nip_args)
      assert StatePurgeQueue.lookup(:storage, Enum.random(server.storages))

      StatePurgeQueue.sync()

      # Cache was updated; it no longer has that NC
      {:ok, new_server} = CacheQuery.from_server_get_all(server_id)
      assert Enum.empty?(new_server.networks)

      # Cant query the server by its NIP (since it's no longer assigned to it)
      assert {:error, reason} =
        CacheQuery.from_nip_get_server(nip.network_id, nip.ip)
      assert reason == {:nip, :notfound}

      # Clean
      refute StatePurgeQueue.lookup(:server, server_id)
      refute StatePurgeQueue.lookup(:network, {nip.network_id, nip.ip})

      # Now we'll reassign this NC to the NIC
      {:ok, nc} = NetworkInternal.Connection.update_nic(nc, nic)
      assert NetworkInternal.Connection.fetch_by_nic(nc.nic_id)

      # Flagged as purged
      assert StatePurgeQueue.lookup(:server, server_id)
      assert StatePurgeQueue.lookup(:storage, Enum.random(server.storages))
      # Network wasn't flagged because the NIP wasn't on cache
      refute StatePurgeQueue.lookup(:network, nip_args)

      StatePurgeQueue.sync()

      {:ok, new_server2} = CacheQuery.from_server_get_all(server_id)
      new_nip = List.first(new_server2.networks)
      assert nip == new_nip

      CacheHelper.sync_test()
    end

    test "changing NIC (cold)", context do
      server_id = context.server.server_id

      {:ok, server} = BuilderInternal.by_server(server_id)

      nip = Enum.random(server.networks)
      nc = NetworkInternal.Connection.fetch(nip.network_id, nip.ip)
      nic = ComponentQuery.fetch(nc.nic_id)

      assert_miss CacheInternal.direct_query(:server, server_id)

      refute StatePurgeQueue.lookup(:server, server_id)
      refute StatePurgeQueue.lookup(:network, {nip.network_id, nip.ip})

      # Nilify
      {:ok, nc} = NetworkInternal.Connection.update_nic(nc, nil)

      refute StatePurgeQueue.lookup(:server, server_id)
      nip_args = {to_string(nip.network_id), nip.ip}
      assert StatePurgeQueue.lookup(:network, nip_args)
      refute StatePurgeQueue.lookup(:storage, Enum.random(server.storages))

      StatePurgeQueue.sync()

      # Cache was updated; it no longer has that NC
      {:ok, new_server} = CacheQuery.from_server_get_all(server_id)
      assert Enum.empty?(new_server.networks)

      # Cant query the server by its NIP (since it's no longer assigned to it)
      assert {:error, reason} =
        CacheQuery.from_nip_get_server(nip.network_id, nip.ip)
      assert reason == {:nip, :notfound}

      StatePurgeQueue.sync()

      # Make sure we are at a cold state
      CacheHelper.empty_cache()
      assert_miss CacheInternal.direct_query(:server, server_id)

      # Now we'll reassing the NC to the NIC
      {:ok, _nc} = NetworkInternal.Connection.update_nic(nc, nic)

      # Nothing was changed, since nothing exists on cache
      refute StatePurgeQueue.lookup(:server, server_id)
      refute StatePurgeQueue.lookup(:network, nip_args)
      refute StatePurgeQueue.lookup(:storage, Enum.random(server.storages))

      CacheHelper.sync_test()
    end
  end
end
