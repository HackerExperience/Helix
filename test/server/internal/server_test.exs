defmodule Helix.Server.Internal.ServerTest do

  use Helix.Test.Case.Integration

  alias Helix.Test.Cache.Helper, as: CacheHelper
  alias Helix.Hardware.Internal.Motherboard, as: MotherboardInternal
  alias Helix.Hardware.Model.Component
  alias Helix.Hardware.Model.Motherboard
  alias Helix.Server.Internal.Server, as: ServerInternal
  alias Helix.Server.Model.Server
  alias Helix.Server.Repo

  alias Helix.Test.Server.Factory

  # FIXME: add more tests
  setup do
    alias Helix.Test.Account.Factory, as: AccountFactory
    alias Helix.Account.Action.Flow.Account, as: AccountFlow

    account = AccountFactory.insert(:account)
    {:ok, %{server: server}} = AccountFlow.setup_account(account)

    :timer.sleep(100)
    CacheHelper.sync_test()

    {:ok, account: account, server: server}
  end

  describe "creating" do
    test "succeeds with valid server_type" do
      params = %{server_type: Factory.random_server_type()}
      assert {:ok, _} = ServerInternal.create(params)
    end

    test "fails with invalid server_type" do
      {:error, cs} = ServerInternal.create(%{server_type: :foobar})
      assert :server_type in Keyword.keys(cs.errors)
    end
  end

  describe "fetch/1" do
    test "succeeds by id" do
      server = Factory.insert(:server)
      assert %Server{} = ServerInternal.fetch(server.server_id)
    end

    test "fails when server doesn't exists" do
      refute ServerInternal.fetch(Server.ID.generate())
    end
  end

  describe "fetch_by_motherboard/1" do
    test "succeeds with mobo id", context do
      server = context.server
      result = ServerInternal.fetch_by_motherboard(server.motherboard_id)
      assert server.server_id == result.server_id
    end

    test "fails with non-existing id" do
      refute ServerInternal.fetch_by_motherboard(Component.ID.generate())
    end

    test "succeeds with mobo component", context do
      server = context.server
      motherboard = MotherboardInternal.fetch(server.motherboard_id)
      result = ServerInternal.fetch_by_motherboard(motherboard)

      assert result.server_id == context.server.server_id
    end

    test "fails with non-existing component" do
      bogus_mobus = %Motherboard{motherboard_id: Component.ID.generate()}
      refute ServerInternal.fetch_by_motherboard(bogus_mobus)
    end
  end

  test "delete/1 removes entry" do
    server = Factory.insert(:server)
    assert Repo.get(Server, server.server_id)

    ServerInternal.delete(server)

    refute Repo.get(Server, server.server_id)

    CacheHelper.sync_test()
  end
end
