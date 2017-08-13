defmodule Helix.Universe.Bank.Event.BankTransferTest do

  use Helix.Test.IntegrationCase

  alias Helix.Process.Action.Process, as: ProcessAction
  alias Helix.Process.Query.Process, as: ProcessQuery
  alias Helix.Universe.Bank.Action.Flow.BankTransfer, as: BankTransferFlow
  alias Helix.Universe.Bank.Internal.BankAccount, as: BankAccountInternal
  alias Helix.Universe.Bank.Internal.BankTransfer, as: BankTransferInternal

  alias HELL.TestHelper.Setup
  alias Helix.Test.Process.TOPHelper

  describe "transfer_aborted/1" do
    test "life cycle" do
      amount = 100_000_000
      acc1 = Setup.bank_account([balance: amount])
      acc2 = Setup.bank_account()
      {_, player} = Setup.server()

      {:ok, process} = BankTransferFlow.start(acc1, acc2, amount, player)
      transfer_id = process.process_data.transfer_id

      assert ProcessQuery.fetch(process)
      assert BankTransferInternal.fetch(transfer_id)
      assert BankAccountInternal.get_balance(acc1.account_number) == 0
      assert BankAccountInternal.get_balance(acc2.account_number) == 0

      # Kill (abort)
      ProcessAction.kill(process, :porquesim)

      :timer.sleep(100)

      # Ensure bank data is consistent
      refute BankTransferInternal.fetch(transfer_id)
      assert BankAccountInternal.get_balance(acc1.account_number) == amount
      assert BankAccountInternal.get_balance(acc2.account_number) == 0

      # And process no longer exists..
      refute ProcessQuery.fetch(process)

      TOPHelper.top_stop(process.gateway_id)
    end
  end
end
