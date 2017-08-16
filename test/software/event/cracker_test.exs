defmodule Helix.Software.Event.CrackerTest do

  use Helix.Test.IntegrationCase

  alias Helix.Process.Action.Process, as: ProcessAction
  alias Helix.Universe.Bank.Query.Bank, as: BankQuery
  alias Helix.Software.Model.SoftwareType.Cracker.Overflow.ConclusionEvent,
    as: OverflowConclusionEvent
  alias Helix.Software.Event.Cracker, as: CrackerHandler

  alias HELL.TestHelper.Setup
  alias Helix.Test.Process.TOPHelper

  describe "overflow_conclusion/1 on wire transfer connection" do
    test "life cycle for overflow attack against wire transfer connection" do
      process = Setup.wire_transfer_flow()
      transfer_id = process.process_data.transfer_id

      # Simulate completion of overflow process
      event = %OverflowConclusionEvent{
        target_process_id: process.process_id
      }

      # Returns a token
      assert {:ok, token_id} = CrackerHandler.overflow_conclusion(event)

      # The returned token is valid
      token = BankQuery.fetch_token(token_id)
      assert token

      # And belongs to the transfer's source account
      transfer = BankQuery.fetch_transfer(transfer_id)
      assert token.atm_id == transfer.atm_from
      assert token.account_number == transfer.account_from

      TOPHelper.top_stop(process.gateway_id)
    end
  end

  # TODO: Requires OverflowFlow
  @tag :pending
  describe "bank_transfer_aborted/1" do
    test "it stops all overflow attacks running on aborted transfer" do
      process = Setup.wire_transfer_flow()
      # transfer_id = process.process_data.transfer_id

      # Abort transfer
      ProcessAction.kill(process, :normal)

      :timer.sleep(100)

      TOPHelper.top_stop(process.gateway_id)
    end
  end
end
