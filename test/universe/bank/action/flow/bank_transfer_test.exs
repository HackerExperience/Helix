defmodule Helix.Universe.Bank.Action.Flow.BankTransferTest do

  use Helix.Test.IntegrationCase

  alias HELL.TestHelper.Setup
  alias Helix.Process.Query.Process, as: ProcessQuery
  alias Helix.Universe.Bank.Action.Flow.BankTransfer, as: BankTransferFlow
  alias Helix.Universe.Bank.Internal.BankAccount, as: BankAccountInternal
  alias Helix.Universe.Bank.Internal.BankTransfer, as: BankTransferInternal

  describe "start/1" do
    @tag :slow
    test "default life cycle" do
      amount = 1
      acc1 = Setup.bank_account([balance: amount])
      acc2 = Setup.bank_account()
      {_, player} = Setup.server()

      # They see me flowin', they hatin'
      {:ok, flow} = BankTransferFlow.start(acc1, acc2, amount, player)
      transfer_id = flow.process_data.transfer_id

      # Ensure it was added to the DB
      assert BankTransferInternal.fetch(transfer_id)

      # Ensure process was created
      assert ProcessQuery.fetch(flow.process_id)

      # Ensure it removed money from source, but did not transfer yet
      assert BankAccountInternal.get_balance(acc1.account_number) == 0
      assert BankAccountInternal.get_balance(acc2.account_number) == 0

      # Wait for it.... Transferring $0.01 is quite quick (nope)
      :timer.sleep(1100)

      # Ensure transfer was completed
      refute BankTransferInternal.fetch(transfer_id)
      refute ProcessQuery.fetch(flow.process_id)
      assert BankAccountInternal.get_balance(acc1.account_number) == 0
      assert BankAccountInternal.get_balance(acc2.account_number) == amount
    end
  end
end
