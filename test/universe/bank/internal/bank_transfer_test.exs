defmodule Helix.Universe.Bank.Internal.BankTransferTest do

  use Helix.Test.IntegrationCase

  import Helix.Test.IDCase

  alias HELL.TestHelper.Random
  alias HELL.TestHelper.Setup
  alias Helix.Universe.Bank.Internal.BankAccount, as: BankAccountInternal
  alias Helix.Universe.Bank.Internal.BankTransfer, as: BankTransferInternal

  describe "fetch/1" do
    test "it fetches!" do
      transfer = Setup.bank_transfer()
      assert BankTransferInternal.fetch(transfer.transfer_id)
    end

    test "with invalid data" do
      refute BankTransferInternal.fetch(Random.pk())
    end
  end

  describe "start/4" do

    test "with valid data" do
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
      assert BankAccountInternal.get_balance(acc1.account_number) == 0

      # Nothing was added to the acc2 (must wait for conclusion)
      assert BankAccountInternal.get_balance(acc2.account_number) == 0

      # Ensure bank_transfer entry was created
      assert BankTransferInternal.fetch(transfer.transfer_id)
    end

    test "with insufficient funds" do
      acc1 = Setup.bank_account()
      acc2 = Setup.bank_account()
      error = {:error, {:funds, :insufficient}}
      assert error == BankTransferInternal.start(acc1, acc2, 1, Random.pk())
    end
  end

  describe "cancel/1" do
    test "with valid data" do
      transfer = Setup.bank_transfer()

      before_cancel = BankAccountInternal.get_balance(transfer.account_from)

      assert :ok == BankTransferInternal.cancel(transfer.transfer_id)

      # Ensure it reimburses original account money
      after_cancel = BankAccountInternal.get_balance(transfer.account_from)
      assert after_cancel == before_cancel + transfer.amount

      # Ensure it removed the transfer from DB
      refute BankTransferInternal.fetch(transfer.transfer_id)

      # TODO: Ensure it deleted the process
    end

    test "with invalid data" do
      assert {:error, reason} = BankTransferInternal.cancel(Random.pk())
      assert reason == {:transfer, :notfound}
    end
  end

  describe "complete/1" do
    test "with valid data" do
      transfer = Setup.bank_transfer()

      acc_from_before = BankAccountInternal.get_balance(transfer.account_from)
      acc_to_before = BankAccountInternal.get_balance(transfer.account_to)

      assert :ok == BankTransferInternal.complete(transfer.transfer_id)

      # Ensure money was transferred around correctly
      acc_from_after = BankAccountInternal.get_balance(transfer.account_from)
      acc_to_after = BankAccountInternal.get_balance(transfer.account_to)

      assert acc_from_before == acc_from_after
      assert acc_to_after == acc_to_before + transfer.amount

      # Ensure entry was removed
      refute BankTransferInternal.fetch(transfer.transfer_id)
    end
  end

  describe "transfer life cycle" do
    test "default case" do
      amount = 250
      acc1 = Setup.bank_account([balance: amount])
      acc2 = Setup.bank_account()
      started_by = Random.pk()

      acc1_before_start = BankAccountInternal.get_balance(acc1.account_number)
      acc2_before_start = BankAccountInternal.get_balance(acc2.account_number)

      # Start
      {:ok, transfer} = BankTransferInternal.start(acc1, acc2, amount, started_by)

      acc1_after_start = BankAccountInternal.get_balance(acc1.account_number)
      acc2_after_start = BankAccountInternal.get_balance(acc2.account_number)

      assert acc1_after_start == acc1_before_start - amount
      assert acc2_after_start == acc2_before_start

      # Complete
      BankTransferInternal.complete(transfer.transfer_id)

      acc1_after_complete = BankAccountInternal.get_balance(acc1.account_number)
      acc2_after_complete = BankAccountInternal.get_balance(acc2.account_number)

      # troca troca was successful
      assert acc1_after_complete == acc1_before_start - amount
      assert acc2_after_complete == acc2_before_start + amount
    end

    test "transfer cancellation case" do
      amount = 250
      acc1 = Setup.bank_account([balance: amount])
      acc2 = Setup.bank_account()
      started_by = Random.pk()

      acc1_before_start = BankAccountInternal.get_balance(acc1.account_number)
      acc2_before_start = BankAccountInternal.get_balance(acc2.account_number)

      # Start
      {:ok, transfer} = BankTransferInternal.start(acc1, acc2, amount, started_by)

      acc1_after_start = BankAccountInternal.get_balance(acc1.account_number)
      acc2_after_start = BankAccountInternal.get_balance(acc2.account_number)

      assert acc1_after_start == acc1_before_start - amount
      assert acc2_after_start == acc2_before_start

      # Cancel
      BankTransferInternal.cancel(transfer.transfer_id)

      acc1_after_complete = BankAccountInternal.get_balance(acc1.account_number)
      acc2_after_complete = BankAccountInternal.get_balance(acc2.account_number)

      # Bad bad transfer no troca troca for you
      assert acc1_after_complete == acc1_before_start
      assert acc2_after_complete == acc2_before_start
    end
  end
end
