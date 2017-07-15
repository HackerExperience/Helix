defmodule Helix.Cache.Internal.CacheTest do

  use Helix.Test.IntegrationCase

  alias HELL.TestHelper.Random
  alias Helix.Server.Action.Server, as: ServerAction
  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Hardware.Query.Motherboard, as: MotherboardQuery
  alias Helix.Cache.Internal.Cache, as: CacheInternal
  alias Helix.Cache.Internal.Populate, as: PopulateInternal
  alias Helix.Cache.Internal.Purge, as: PurgeInternal
  alias Helix.Cache.Repo

  setup do
    alias Helix.Account.Factory, as: AccountFactory
    alias Helix.Account.Action.Flow.Account, as: AccountFlow

    account = AccountFactory.insert(:account)
    {:ok, %{server: server}} = AccountFlow.setup_account(account)

    {:ok, account: account, server: server}
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

    test "filters out expired entries", context do
      server_id = context.server.server_id

      {:ok, server} = PopulateInternal.populate(:server, server_id)

      :ok = PurgeInternal.purge(:server, server_id)

      expired_date = Ecto.DateTime.from_unix!(DateTime.to_unix(DateTime.utc_now()) - 600000, :second)

      %{server | expiration_date: expired_date}
      |> Repo.insert()

      :miss = CacheInternal.direct_query(:server, server_id)

      :timer.sleep(10)
    end

    test "repopulates expired entries", context do
      server_id = context.server.server_id

      {:ok, server} = PopulateInternal.populate(:server, server_id)

      :ok = PurgeInternal.purge(:server, server_id)

      expired_date = Ecto.DateTime.from_unix!(DateTime.to_unix(DateTime.utc_now()) - 600000, :second)

      server1 = %{server | expiration_date: expired_date}

      server1
      |> Repo.insert()

      :miss = CacheInternal.direct_query(:server, server_id)

      {:ok, _} = CacheInternal.lookup({:server, :nips}, [server_id])

      {:hit, server2} = CacheInternal.direct_query(:server, server_id)

      assert server2.server_id == server1.server_id
      assert server2.expiration_date > server1.expiration_date

      :timer.sleep(10)
    end
  end
end
