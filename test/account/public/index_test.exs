defmodule Helix.Account.Public.IndexTest do

  use Helix.Test.Case.Integration

  import Helix.Test.Case.ID

  alias Helix.Account.Public.Index, as: AccountIndex

  alias Helix.Test.Network.Setup, as: NetworkSetup
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Universe.Bank.Setup, as: BankSetup

  describe "index/1" do
    test "returns the expected data" do
      {server, %{entity: entity}} = ServerSetup.server()

      {bounce, _} = NetworkSetup.Bounce.bounce(entity_id: entity.entity_id)

      bank_account = BankSetup.account!(owner_id: entity.entity_id, balance: 24)

      index = AccountIndex.index(entity)

      assert index.mainframe == server.server_id
      assert index.inventory
      assert index.bounces == [bounce]
      assert index.bank_accounts == [bank_account]
      assert index.database
      assert index.notifications
    end
  end

  describe "render_index/1" do
    test "returns JSON-friendly index" do
      {server, %{entity: entity}} = ServerSetup.server()

      {bounce, _} = NetworkSetup.Bounce.bounce(entity_id: entity.entity_id)

      bank_account = BankSetup.account!(owner_id: entity.entity_id, balance: 24)

      rendered =
        entity
        |> AccountIndex.index()
        |> AccountIndex.render_index()

      # Mainframe is valid
      assert rendered.mainframe == to_string(server.server_id)

      # Bounce is valid
      assert [rendered_bounce] = rendered.bounces
      assert rendered_bounce.bounce_id == to_string(bounce.bounce_id)
      assert rendered_bounce.name == bounce.name
      Enum.each(rendered_bounce.links, fn link ->
        assert is_binary(link.network_id)
        assert is_binary(link.ip)
      end)

      # BankAccount is valid
      assert [rendered_bank_account] = rendered.bank_accounts
      assert rendered_bank_account.account_number == bank_account.account_number
      assert_id rendered_bank_account.atm_id, bank_account.atm_id
      assert rendered_bank_account.password == bank_account.password
      assert rendered_bank_account.balance == bank_account.balance

      # Database was rendered (full test at DatabaseIndex)
      assert rendered.database

      # Notifications were rendered (full test at AccountNotificationIndex)
      assert rendered.notifications
    end
  end
end
