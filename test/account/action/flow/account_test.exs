defmodule Helix.Account.Action.Flow.AccountTest do

  use Helix.Test.Case.Integration

  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Network.Query.Network, as: NetworkQuery
  alias Helix.Server.Query.Motherboard, as: MotherboardQuery
  alias Helix.Account.Action.Flow.Account, as: AccountFlow

  alias Helix.Test.Cache.Helper, as: CacheHelper
  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Account.Setup, as: AccountSetup

  @internet_id NetworkHelper.internet_id()
  @relay nil

  describe "setup_account/1" do
    test "creates an entity" do
      {account, _} = AccountSetup.account()

      assert {:ok, %{entity: entity, server: server}} =
        AccountFlow.setup_account(account, @relay)

      CacheHelper.sync_test()

      # Generated entity has the correct id
      account_id = EntityQuery.get_entity_id(account)
      entity_id = EntityQuery.get_entity_id(entity)
      assert account_id == entity_id

      # Server is valid and registered to the entity
      assert [server_id] = EntityQuery.get_servers(entity)
      assert server_id == server.server_id
      assert server.motherboard_id

      # Components have been linked to the entity
      components = EntityQuery.get_components(entity)
      assert length(components) == 5

      motherboard = MotherboardQuery.fetch(server.motherboard_id)

      # Server network (ISP connection) is working
      [nic] = MotherboardQuery.get_nics(motherboard)
      nc = NetworkQuery.Connection.fetch_by_nic(nic)

      assert nc.network_id == @internet_id
      assert nc.ip
      assert nc.nic_id == nic.component_id
    end
  end
end
