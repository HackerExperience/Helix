defmodule Helix.Universe.Bank.Action.Flow.BankAccountTest do

  use Helix.Test.IntegrationCase

  alias Helix.Entity.Query.Database, as: DatabaseQuery
  alias Helix.Process.Query.Process, as: ProcessQuery
  alias Helix.Universe.Bank.Action.Flow.BankAccount, as: BankAccountFlow
  alias Helix.Universe.Bank.Query.Bank, as: BankQuery

  alias HELL.TestHelper.Setup
  alias Helix.Test.Entity.Database.Setup, as: DatabaseSetup
  alias Helix.Test.Process.TOPHelper
  alias Helix.Test.Server.Setup, as: ServerSetup

  describe "reveal_password/4" do
    @tag :slow
    test "default life cycle" do
      time_before_event = DateTime.utc_now()
      token = Setup.bank_token()
      acc = BankQuery.fetch_account(token.atm_id, token.account_number)
      {gateway, %{entity: entity}} = ServerSetup.server()

      # There's an entry of this account on the Database
      DatabaseSetup.entry_bank_account([entity_id: entity.entity_id, acc: acc])
      old_entry = DatabaseQuery.fetch_bank_account(entity, acc)
      refute old_entry.password

      # Create process to reveal password
      {:ok, process} =
        BankAccountFlow.reveal_password(
          token.atm_id,
          token.account_number,
          token.token_id,
          gateway.server_id
        )

      # Ensure process is valid
      assert process.gateway_id == gateway.server_id
      assert process.target_server_id == acc.atm_id
      assert process.process_data.token_id == token.token_id
      assert process.process_data.atm_id == acc.atm_id
      assert process.process_data.account_number == acc.account_number

      # TODO: TOPHelper.force_complete_process(process)
      # Sleeping 1 second only works while CPU objective is 1.
      # Adjust properly once TOPHelper helps
      :timer.sleep(1100)

      # Process no longer exists
      refute ProcessQuery.fetch(process.process_id)

      # Ensure it updated the Database entry
      database_entry = DatabaseQuery.fetch_bank_account(entity, acc)
      refute database_entry == old_entry
      assert database_entry.password == acc.password
      assert DateTime.diff(database_entry.last_update, time_before_event) > 0

      TOPHelper.top_stop(process.gateway_id)
    end
  end
end
