defmodule Helix.Universe.Bank.Internal.BankTransferTest do

  use Helix.Test.IntegrationCase

  import Helix.Test.IDCase

  alias HELL.TestHelper.Random
  alias HELL.TestHelper.Setup
  alias Helix.Universe.Bank.Internal.BankAccount, as: BankAccountInternal
  alias Helix.Universe.Bank.Internal.BankTransfer, as: BankTransferInternal
  alias Helix.Universe.Bank.Model.BankTransfer

  describe "fetch/1" do
    test "fetches a transfer" do
      transfer = Setup.bank_transfer()
      assert BankTransferInternal.fetch(transfer.transfer_id)
    end

    test "with invalid transfer" do
      refute BankTransferInternal.fetch(BankTransfer.ID.generate())
    end
  end

  describe "start/4" do
    test "starts a new transfer" do
      acc1 = Setup.bank_account()
      acc2 = Setup.bank_account()
      started_by = Random.pk()
      amount = 500

      BankAccountInternal.deposit(acc1, amount)

      assert {:ok, transfer} =
        BankTransferInternal.start(acc1, acc2, amount, started_by)

      assert transfer.transfer_id
      assert transfer.amount == amount
      assert transfer.account_from == acc1.account_number
      assert transfer.account_to == acc2.account_number
      assert transfer.atm_from == acc1.atm_id
      assert transfer.atm_to == acc2.atm_id
      assert_id transfer.started_by, started_by
      assert transfer.started_time

      # Make sure that relevant amount was removed from the first account
      assert BankAccountInternal.get_balance(acc1) == 0

      # Nothing was added to the acc2 (must wait for conclusion)
      assert BankAccountInternal.get_balance(acc2) == 0

      # Bank transfer entry was created
      assert BankTransferInternal.fetch(transfer.transfer_id)
    end

    test "with insufficient funds" do
      acc1 = Setup.bank_account()
      acc2 = Setup.bank_account()

      error = {:error, {:funds, :insufficient}}
      assert error == BankTransferInternal.start(acc1, acc2, 1, Random.pk())
    end
  end

  describe "abort/1" do
    test "aborts the transfer" do
      transfer = Setup.bank_transfer()

      account_from =
        BankAccountInternal.fetch(transfer.atm_from, transfer.account_from)
      account_to =
        BankAccountInternal.fetch(transfer.atm_to, transfer.account_to)

      before_abort_from = BankAccountInternal.get_balance(account_from)
      before_abort_to = BankAccountInternal.get_balance(account_to)

      assert :ok == BankTransferInternal.abort(transfer)

      # Ensure it reimburses original account money
      after_abort_from = BankAccountInternal.get_balance(account_from)
      assert after_abort_from == before_abort_from + transfer.amount

      # And nothing was added to destination
      after_abort_to = BankAccountInternal.get_balance(account_to)
      assert before_abort_to == after_abort_to

      # Ensure it removed the transfer from DB
      refute BankTransferInternal.fetch(transfer.transfer_id)
    end

    test "with invalid data" do
      fake_transfer = Setup.fake_bank_transfer()
      assert {:error, reason} = BankTransferInternal.abort(fake_transfer)
      assert reason == {:transfer, :notfound}
    end
  end

  describe "complete/1" do
    test "completes the transfer" do
      transfer = Setup.bank_transfer()

      account_from =
        BankAccountInternal.fetch(transfer.atm_from, transfer.account_from)
      account_to =
        BankAccountInternal.fetch(transfer.atm_to, transfer.account_to)

      acc_from_before = BankAccountInternal.get_balance(account_from)
      acc_to_before = BankAccountInternal.get_balance(account_to)

      assert :ok == BankTransferInternal.complete(transfer)

      # Ensure money was transferred around correctly
      acc_from_after = BankAccountInternal.get_balance(account_from)
      acc_to_after = BankAccountInternal.get_balance(account_to)

      assert acc_from_before == acc_from_after
      assert acc_to_after == acc_to_before + transfer.amount

      # Ensure entry was removed
      refute BankTransferInternal.fetch(transfer.transfer_id)
    end
  end

  describe "transfer life cycle" do
    test "default scenario" do
      amount = 250
      acc1 = Setup.bank_account([balance: amount])
      acc2 = Setup.bank_account()
      started_by = Random.pk()

      acc1_before_start = BankAccountInternal.get_balance(acc1)
      acc2_before_start = BankAccountInternal.get_balance(acc2)

      # Start
      {:ok, transfer} =
        BankTransferInternal.start(acc1, acc2, amount, started_by)

      acc1_after_start = BankAccountInternal.get_balance(acc1)
      acc2_after_start = BankAccountInternal.get_balance(acc2)

      assert acc1_after_start == acc1_before_start - amount
      assert acc2_after_start == acc2_before_start

      # Complete
      BankTransferInternal.complete(transfer)

      acc1_after_complete = BankAccountInternal.get_balance(acc1)
      acc2_after_complete = BankAccountInternal.get_balance(acc2)

      # troca troca was successful
      assert acc1_after_complete == acc1_before_start - amount
      assert acc2_after_complete == acc2_before_start + amount
    end

    test "transfer abort scenario" do
      amount = 250
      acc1 = Setup.bank_account([balance: amount])
      acc2 = Setup.bank_account()
      started_by = Random.pk()

      acc1_before_start = BankAccountInternal.get_balance(acc1)
      acc2_before_start = BankAccountInternal.get_balance(acc2)

      # Start
      {:ok, transfer} =
        BankTransferInternal.start(acc1, acc2, amount, started_by)

      acc1_after_start = BankAccountInternal.get_balance(acc1)
      acc2_after_start = BankAccountInternal.get_balance(acc2)

      assert acc1_after_start == acc1_before_start - amount
      assert acc2_after_start == acc2_before_start

      # Abort
      BankTransferInternal.abort(transfer)

      acc1_after_complete = BankAccountInternal.get_balance(acc1)
      acc2_after_complete = BankAccountInternal.get_balance(acc2)

      # Bad bad transfer no troca troca for you
      assert acc1_after_complete == acc1_before_start
      assert acc2_after_complete == acc2_before_start
    end
  end
end
