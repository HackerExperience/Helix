defmodule Helix.Software.Event.CrackerTest do

  use Helix.Test.Case.Integration

  alias Helix.Entity.Query.Database, as: DatabaseQuery
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Process.Action.Process, as: ProcessAction
  alias Helix.Universe.Bank.Query.Bank, as: BankQuery
  alias Helix.Software.Event.Cracker, as: CrackerHandler

  alias Helix.Test.Account.Setup, as: AccountSetup
  alias Helix.Test.Event.Setup, as: EventSetup
  alias Helix.Test.Process.Setup, as: ProcessSetup
  alias Helix.Test.Process.TOPHelper
  alias Helix.Test.Universe.Bank.Setup, as: BankSetup

  describe "overflow_conclusion/1" do
    test "life cycle for overflow attack against wire transfer connection" do
      {process, %{acc1: acc1, player: player}} =
        BankSetup.wire_transfer_flow()
      transfer_id = process.process_data.transfer_id

      # Simulate completion of overflow process
      event = EventSetup.overflow_conclusion(process)

      # Returns a token
      assert {:ok, token_id} = CrackerHandler.overflow_conclusion(event)

      # The returned token is valid
      token = BankQuery.fetch_token(token_id)
      assert token

      # And belongs to the transfer's source account
      transfer = BankQuery.fetch_transfer(transfer_id)
      assert token.atm_id == transfer.atm_from
      assert token.account_number == transfer.account_from

      # Wait for events
      :timer.sleep(100)

      # It added the token to the Hacked Database
      entity_id = EntityQuery.get_entity_id(player)

      database_entry = DatabaseQuery.fetch_bank_account(entity_id, acc1)

      assert database_entry
      assert database_entry.token == token_id
      assert database_entry.atm_id == acc1.atm_id
      assert database_entry.account_number == acc1.account_number
      refute database_entry.password
      refute database_entry.last_login_date

      TOPHelper.top_stop(process.gateway_id)
    end

    test "life cycle for overflow attack against bank login connection" do
      {connection, %{acc: acc}} =
        BankSetup.login_flow()
      {attacker_player, %{server: attacker_server}} =
        AccountSetup.account([with_server: true])

      # Simulate completion of overflow process
      event =
        EventSetup.overflow_conclusion(connection, attacker_server.server_id)

      # Returns a token
      assert {:ok, token_id} = CrackerHandler.overflow_conclusion(event)

      # The returned token is valid
      token = BankQuery.fetch_token(token_id)
      assert token

      # And belongs to the account being used by the connection
      assert token.atm_id == acc.atm_id
      assert token.account_number == acc.account_number

      # Wait for events
      :timer.sleep(100)

      # It added the token to the Hacked Database
      attacker_entity_id = EntityQuery.get_entity_id(attacker_player)

      database_entry =
        DatabaseQuery.fetch_bank_account(attacker_entity_id, acc)

      assert database_entry
      assert database_entry.token == token_id
      assert database_entry.atm_id == acc.atm_id
      assert database_entry.account_number == acc.account_number
      refute database_entry.password
      refute database_entry.last_login_date

      TOPHelper.top_stop(attacker_server.server_id)
    end
  end

  # TODO: Requires OverflowFlow
  @tag :pending
  describe "bank_transfer_aborted/1" do
    test "it stops all overflow attacks running on aborted transfer" do
      {process, _} = BankSetup.wire_transfer_flow()
      # transfer_id = process.process_data.transfer_id

      # Abort transfer
      ProcessAction.kill(process, :normal)

      :timer.sleep(100)

      TOPHelper.top_stop(process.gateway_id)
    end
  end

  @tag :pending
  test "it stops overflow attacks when bank_login connection was closed"

  describe "bruteforce_conclusion/1" do
    test "retrieves the password on success" do
      {process, _} = ProcessSetup.bruteforce_flow()

      event = EventSetup.bruteforce_conclusion(process)

      assert {:ok, _password} =
        CrackerHandler.bruteforce_conclusion(event)

      TOPHelper.top_stop(process.gateway_id)
    end

    test "fails when target server is not found" do
      event = EventSetup.bruteforce_conclusion()

      assert {:error, reason} =
        CrackerHandler.bruteforce_conclusion(event)

      # Server not found! This may happen if target changed her IP mid-process
      assert reason == {:nip, :notfound}
    end
  end

  @tag :pending
  test "bruteforce process is stopped when cracker (file_id) is deleted"
end
