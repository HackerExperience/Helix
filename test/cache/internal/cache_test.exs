defmodule Helix.Cache.Internal.CacheTest do

  use Helix.Test.IntegrationCase

  alias HELL.TestHelper.Random
  alias Helix.Server.Action.Server, as: ServerAction
  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Hardware.Query.Motherboard, as: MotherboardQuery
  alias Helix.Cache.Internal.Cache, as: CacheInternal
  alias Helix.Cache.Internal.Populate, as: PopulateInternal
  alias Helix.Cache.Model.ServerCache
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

  describe "lookup/2" do
    test "populates data after miss", context do
      server_id = context.server.server_id

      {:ok, result} = CacheInternal.lookup({:server, :nips}, [server_id])

      assert result == ServerQuery.get_nips(server_id)

      :timer.sleep(10)
    end

    test "returns cached data", context do
      server_id = context.server.server_id
      motherboard_id = context.server.motherboard_id
      storages = MotherboardQuery.get_storages(motherboard_id)

      # Insert directly into cache
      {:ok, cached} = PopulateInternal.populate(:server, server_id)

      {:ok, result} = CacheInternal.lookup({:server, :storages}, [server_id])

      assert result == cached.storages
      assert result == [storages.storage_id]

      :timer.sleep(10)
    end

    test "fails on invalid data"  do
      {:error, _} = CacheInternal.lookup({:server, :resources}, [Random.pk()])
    end

    test "returns valid but empty data", context do
      server_id = context.server.server_id

      ServerAction.detach(context.server)
      {:ok, storage} = CacheInternal.lookup({:server, :storages}, [server_id])

      assert storage == nil
    end
  end
end
