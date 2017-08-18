defmodule Helix.Universe.Bank.Event.BankTransferTest do

  use Helix.Test.Case.Integration

  alias Helix.Process.Action.Process, as: ProcessAction
  alias Helix.Process.Query.Process, as: ProcessQuery
  alias Helix.Universe.Bank.Action.Flow.BankTransfer, as: BankTransferFlow
  alias Helix.Universe.Bank.Internal.BankAccount, as: BankAccountInternal
  alias Helix.Universe.Bank.Internal.BankTransfer, as: BankTransferInternal

  alias Helix.Test.Account.Setup, as: AccountSetup
  alias Helix.Test.Process.TOPHelper
  alias Helix.Test.Universe.Bank.Setup, as: BankSetup

  describe "transfer_aborted/1" do
    test "life cycle" do
      amount = 100_000_000
      {acc1, _} = BankSetup.account([balance: amount])
      {acc2, _} = BankSetup.account()
      {player, _} = AccountSetup.account([with_server: true])

      {:ok, process} = BankTransferFlow.start(acc1, acc2, amount, player)
      transfer_id = process.process_data.transfer_id

      assert ProcessQuery.fetch(process)
      assert BankTransferInternal.fetch(transfer_id)
      assert BankAccountInternal.get_balance(acc1) == 0
      assert BankAccountInternal.get_balance(acc2) == 0

      # Kill (abort)
      ProcessAction.kill(process, :porquesim)

      :timer.sleep(100)

      # Ensure bank data is consistent
      refute BankTransferInternal.fetch(transfer_id)
      assert BankAccountInternal.get_balance(acc1) == amount
      assert BankAccountInternal.get_balance(acc2) == 0

      # And process no longer exists..
      refute ProcessQuery.fetch(process)

      TOPHelper.top_stop(process.gateway_id)
    end
  end
end
