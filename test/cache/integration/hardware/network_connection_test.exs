defmodule Helix.Cache.Integration.Hardware.NetworkConnectionTest do

  use Helix.Test.IntegrationCase

  alias Helix.Hardware.Internal.NetworkConnection, as: NetworkConnectionInternal
  alias Helix.Cache.Helper, as: CacheHelper
  alias Helix.Cache.Internal.Builder, as: BuilderInternal
  alias Helix.Cache.Internal.Populate, as: PopulateInternal
  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Cache.State.PurgeQueue, as: StatePurgeQueue

  setup do
    CacheHelper.cache_context()
  end

  describe "network connection actions" do
    test "changing ip", context do
      server_id = context.server.server_id

      {:ok, server} = PopulateInternal.populate(:by_server, server_id)

      nip = Enum.random(server.networks)
      nc = NetworkConnectionInternal.fetch_by_nip(nip.network_id, nip.ip)
      new_ip = HELL.IPv4.autogenerate()

      refute StatePurgeQueue.lookup(:server, server_id)
      refute StatePurgeQueue.lookup(:network, {nip.network_id, nip.ip})

      {:ok, _} = NetworkConnectionInternal.update_ip(nc, new_ip)

      assert StatePurgeQueue.lookup(:server, server_id)
      assert StatePurgeQueue.lookup(:network, {nip.network_id, nip.ip})
      assert StatePurgeQueue.lookup(:network, {nip.network_id, new_ip})
      assert StatePurgeQueue.lookup(:storage, Enum.random(server.storages))
      assert StatePurgeQueue.lookup(:component, Enum.random(server.components))
      assert StatePurgeQueue.lookup(:component, server.motherboard_id)

      {:ok, server2} = CacheQuery.from_server_get_all(server_id)
      refute Map.has_key?(server2, :expiration_date)

      nip2 = Enum.random(server2.networks)
      assert nip2 == %{network_id: nip.network_id, ip: new_ip}

      {:error, reason} = CacheQuery.from_nip_get_server(nip.network_id, nip.ip)
      assert reason == {:nip, :notfound}

      {:ok, server3} = CacheQuery.from_nip_get_server(nip.network_id, new_ip)
      assert server3 == server_id

      StatePurgeQueue.sync()

      {:ok, server4} = CacheQuery.from_server_get_all(server_id)
      assert server4.expiration_date
      assert server4.networks == server2.networks
    end

    test "changing ip (cold)", context do
      server_id = context.server.server_id

      {:ok, server} = BuilderInternal.by_server(server_id)

      nip = Enum.random(server.networks)
      nc = NetworkConnectionInternal.fetch_by_nip(nip.network_id, nip.ip)
      new_ip = HELL.IPv4.autogenerate()

      refute StatePurgeQueue.lookup(:server, server_id)
      refute StatePurgeQueue.lookup(:network, {nip.network_id, nip.ip})

      {:ok, _} = NetworkConnectionInternal.update_ip(nc, new_ip)

      assert StatePurgeQueue.lookup(:network, {nip.network_id, nip.ip})
      assert StatePurgeQueue.lookup(:network, {nip.network_id, new_ip})
      refute StatePurgeQueue.lookup(:server, server_id)
      refute StatePurgeQueue.lookup(:storage, Enum.random(server.storages))
      refute StatePurgeQueue.lookup(:component, Enum.random(server.components))
      refute StatePurgeQueue.lookup(:component, server.motherboard_id)

      CacheHelper.sync_test()
    end
  end
end
