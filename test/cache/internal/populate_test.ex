defmodule Helix.Cache.Internal.PopulateTest do

  use Helix.Test.IntegrationCase

  alias Helix.Server.Action.Server, as: ServerAction
  alias Helix.Cache.Internal.Cache, as: CacheInternal
  alias Helix.Cache.Internal.Populate, as: PopulateInternal
  alias Helix.Cache.Model.ComponentCache
  alias Helix.Cache.Model.ServerCache
  alias Helix.Cache.Model.StorageCache
  alias Helix.Cache.Model.NetworkCache
  alias Helix.Cache.Repo

  setup do
    alias Helix.Account.Factory, as: AccountFactory
    alias Helix.Account.Action.Flow.Account, as: AccountFlow

    account = AccountFactory.insert(:account)
    {:ok, %{server: server}} = AccountFlow.setup_account(account)

    {:ok, account: account, server: server}
  end

  def direct_cache_query(server_id) do
    ServerCache.Query.by_server(server_id)
    |> Repo.one
  end

  describe "populate/2,3" do
    test "server side-populates other caches", context do
      server_id = context.server.server_id
      motherboard_id = context.server.motherboard_id

      {:ok, [nip]} = CacheInternal.lookup({:server, :nips}, [server_id])
      {:ok, [storage_id]} = CacheInternal.lookup({:server, :storages}, [server_id])
      {:ok, components} = CacheInternal.lookup({:server, :components}, [server_id])

      cached_nip = NetworkCache.Query.by_nip(nip.network_id, nip.ip)
      |> Repo.one

      refute cached_nip == nil
      assert cached_nip.server_id == server_id

      cached_storage = StorageCache.Query.by_storage(storage_id)
      |> Repo.one

      refute cached_storage == nil
      assert cached_storage.storage_id == storage_id

      cached_components = ComponentCache.Query.by_component(List.first(components))
      |> Repo.one

      refute cached_components == nil
      assert cached_components.motherboard_id == motherboard_id

      :timer.sleep(10)
    end

    test "pre-existing cached entries are updated", context do
      server_id = context.server.server_id

      {:ok, server1} = PopulateInternal.populate(:server, server_id)
      ServerAction.detach(context.server)
      {:ok, server2} = PopulateInternal.populate(:server, server_id)

      # Comparing the expiration_time could be a better idea, and it was my
      # first attempt, but it is stored with second-level precision. So I'd
      # have to block this test for 1 second, making it the longest one.
      refute server1 == server2
      assert server2.motherboard_id == nil

      :timer.sleep(10)
    end
  end
end
