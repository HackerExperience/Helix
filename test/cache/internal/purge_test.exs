defmodule Helix.Cache.Internal.PurgeTest do

  use Helix.Test.IntegrationCase

  alias Helix.Hardware.Internal.NetworkConnection, as: NetworkConnectionInternal
  alias Helix.Cache.Internal.Cache, as: CacheInternal
  alias Helix.Cache.Internal.Populate, as: PopulateInternal

  setup do
    alias Helix.Account.Factory, as: AccountFactory
    alias Helix.Account.Action.Flow.Account, as: AccountFlow

    account = AccountFactory.insert(:account)
    {:ok, %{server: server}} = AccountFlow.setup_account(account)

    {:ok, account: account, server: server}
  end

  # REMEMBER:
  # - PurgeInternal.purge is SYNCHRONOUS
  #   - (but side-population isn't)
  # - CacheInternal.purge is ASYNCHRONOUS
  #   - (but mark_as_purged/2 isn't)

  describe "purge/2" do
    test "existing data is updated", context do
      server_id = context.server.server_id

      # Add server server
      {:ok, _} = PopulateInternal.populate(:server, server_id)
      :timer.sleep(10)

      {:hit, server1} = CacheInternal.direct_query(:server, server_id)

      # Modify server
      nip = List.first(server1.networks)
      nc = NetworkConnectionInternal.fetch_by_nip("::", nip.ip)
      new_ip = HELL.IPv4.autogenerate()
      {:ok, _} = NetworkConnectionInternal.update_ip(nc, new_ip)
      :timer.sleep(10)
<<<<<<< HEAD
    end

    test "issues a noop on non-existing data"  do
      assert :nocache == PurgeInternal.purge(:server, Random.pk())
    end
  end

  describe "purge logic" do
    test "purging server deletes everything", context do
      server_id = context.server.server_id

      {:ok, [nip]} = CacheInternal.lookup({:server, :nips}, [server_id])
      {:ok, [storage_id]} = CacheInternal.lookup({:server, :storages}, [server_id])
      {:ok, components} = CacheInternal.lookup({:server, :components}, [server_id])
=======
>>>>>>> b40911d... Consolidate and test PurgeQueue

      # Query again
      {:ok, server2} = CacheInternal.lookup(:server, [server_id])

      server2_ip = server2.networks
      |> List.first()
      |> Map.get(:ip)

<<<<<<< HEAD
=======
      assert server1 != server2
      assert server1.server_id == server2.server_id
      refute nip.ip == server2_ip
      assert server2_ip == new_ip

>>>>>>> b40911d... Consolidate and test PurgeQueue
      :timer.sleep(10)
    end

    test "populates non-existing data", context  do
      server_id = context.server.server_id

      :miss = CacheInternal.direct_query(:server, server_id)

      refute CacheInternal.is_marked_as_purged(:server, server_id)

      CacheInternal.purge(:server, server_id)

      assert CacheInternal.is_marked_as_purged(:server, server_id)

      :miss = CacheInternal.direct_query(:server, server_id)
      :miss = CacheInternal.direct_query(:server, server_id)
      :miss = CacheInternal.direct_query(:server, server_id)

      # TODO: PurgeQueue.sync
      :timer.sleep(30)

      {:hit, server} = CacheInternal.direct_query(:server, server_id)

      refute CacheInternal.is_marked_as_purged(:server, server_id)

      assert server.server_id == server_id

      :timer.sleep(10)
    end
  end
end
