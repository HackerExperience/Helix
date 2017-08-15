defmodule Helix.Universe.Bank.Action.Flow.BankTransferTest do

  use Helix.Test.IntegrationCase

  alias Helix.Process.Query.Process, as: ProcessQuery
  alias Helix.Universe.Bank.Action.Flow.BankTransfer, as: BankTransferFlow
  alias Helix.Universe.Bank.Internal.BankAccount, as: BankAccountInternal
  alias Helix.Universe.Bank.Internal.BankTransfer, as: BankTransferInternal

  alias HELL.TestHelper.Setup
  alias Helix.Test.Process.TOPHelper

  describe "start/1" do
    @tag :slow
    test "default life cycle" do
      amount = 1
      acc1 = Setup.bank_account([balance: amount])
      acc2 = Setup.bank_account()
      {_, player} = Setup.server()

      # They see me flowin', they hatin'
      {:ok, process} = BankTransferFlow.start(acc1, acc2, amount, player)
      transfer_id = process.process_data.transfer_id

      # Ensure it was added to the DB
      assert BankTransferInternal.fetch(transfer_id)

      # Ensure process was created
      assert ProcessQuery.fetch(process.process_id)

      # Ensure it removed money from source, but did not transfer yet
      assert BankAccountInternal.get_balance(acc1) == 0
      assert BankAccountInternal.get_balance(acc2) == 0

      # Wait for it.... Transferring $0.01 is quite quick (nope)
      :timer.sleep(1100)

      # Ensure transfer was completed
      refute BankTransferInternal.fetch(transfer_id)
      refute ProcessQuery.fetch(process.process_id)
      assert BankAccountInternal.get_balance(acc1) == 0
      assert BankAccountInternal.get_balance(acc2) == amount

      TOPHelper.top_stop(process.gateway_id)
    end
  end
end
