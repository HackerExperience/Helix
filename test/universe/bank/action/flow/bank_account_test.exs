defmodule Helix.Universe.Bank.Action.Flow.BankAccountTest do

  use Helix.Test.IntegrationCase

  alias Helix.Process.Query.Process, as: ProcessQuery
  alias Helix.Universe.Bank.Action.Flow.BankAccount, as: BankAccountFlow
  alias Helix.Universe.Bank.Query.Bank, as: BankQuery

  alias HELL.TestHelper.Setup
  alias Helix.Test.Process.TOPHelper

  describe "reveal_password/4" do
    @tag :slow
    test "default life cycle" do
      token = Setup.bank_token()
      acc = BankQuery.fetch_account(token.atm_id, token.account_number)
      {gateway, _} = Setup.server()

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

      refute ProcessQuery.fetch(process.process_id)

      TOPHelper.top_stop(process.gateway_id)
    end
  end
end
