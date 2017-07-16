defmodule Helix.Cache.State.PurgeQueueTest do

  use Helix.Test.IntegrationCase

  alias Helix.Hardware.Query.Motherboard, as: MotherboardQuery
  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Server.Action.Server, as: ServerAction
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

  describe "PurgeQueue API" do
  end

  describe "PurgeQueue functionality" do
  end
end
