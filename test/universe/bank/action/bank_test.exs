defmodule Helix.Universe.Bank.Action.BankTest do

  use Helix.Test.IntegrationCase

  import Helix.Test.IDCase

  alias HELL.TestHelper.Random
  alias HELL.TestHelper.Setup
  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Universe.Bank.Action.Bank, as: BankAction
  alias Helix.Universe.Bank.Internal.BankAccount, as: BankAccountInternal
  alias Helix.Universe.Bank.Internal.BankTransfer, as: BankTransferInternal

  alias Helix.Universe.NPC.Helper, as: NPCHelper

  describe "start_transfer/4" do
    test "with valid data" do
      amount = 500
      acc1 = Setup.bank_account([balance: amount])
      acc2 = Setup.bank_account()
      {_, player} = Setup.server()

      assert {:ok, transfer} =
        BankAction.start_transfer(acc1, acc2, amount, player)

      assert BankTransferInternal.fetch(transfer)
      assert BankAccountInternal.get_balance(acc1) == 0
      assert BankAccountInternal.get_balance(acc2) == 0
    end

    test "with insufficient funds" do
      amount = 500
      acc1 = Setup.bank_account([balance: 100])
      acc2 = Setup.bank_account()
      {_, player} = Setup.server()

      assert {:error, {:funds, :insufficient}} =
        BankAction.start_transfer(acc1, acc2, amount, player)

      assert BankAccountInternal.get_balance(acc1) == 100
      assert BankAccountInternal.get_balance(acc2) == 0
    end
  end

  describe "complete_transfer/1" do
    test "with valid data" do
      amount = 100
      transfer = Setup.bank_transfer([amount: amount])

      assert :ok == BankAction.complete_transfer(transfer)

      refute BankTransferInternal.fetch(transfer)
      assert BankAccountInternal.get_balance(transfer.account_from) == 0
      assert BankAccountInternal.get_balance(transfer.account_to) == amount
    end

    test "with invalid data" do
      assert {:error, reason} = BankAction.complete_transfer(Random.pk())
      assert reason == {:transfer, :notfound}
    end
  end

  describe "abort_transfer/1" do
    test "with valid data" do
      amount = 100
      transfer = Setup.bank_transfer([amount: amount])

      assert :ok == BankAction.abort_transfer(transfer)

      refute BankTransferInternal.fetch(transfer)
      assert BankAccountInternal.get_balance(transfer.account_from) == amount
      assert BankAccountInternal.get_balance(transfer.account_to) == 0
    end

    test "with invalid data" do
      assert {:error, reason} = BankAction.abort_transfer(Random.pk())
      assert reason == {:transfer, :notfound}
    end
  end

  describe "open_account/2" do
    test "default case" do
      {_, player} = Setup.server()
      bank = NPCHelper.bank()
      atm =
        NPCHelper.bank()
        |> Map.get(:servers)
        |> Enum.random()
        |> Map.get(:id)
        |> ServerQuery.fetch()

      assert {:ok, acc} = BankAction.open_account(player, atm)

      assert acc.account_number
      assert acc.owner_id == player.account_id
      assert acc.atm_id == atm.server_id
      assert_id acc.bank_id, bank.id
      assert acc.balance == 0
    end
  end

  describe "close_account/1" do
    test "it closes the account" do
      acc = Setup.bank_account()

      assert BankAccountInternal.fetch(acc.account_number)
      assert :ok == BankAction.close_account(acc)
      refute BankAccountInternal.fetch(acc.account_number)
    end

    test "it refuses to close non-empty accounts" do
      acc = Setup.bank_account([balance: 1])

      assert BankAccountInternal.fetch(acc.account_number)
      assert {:error, reason} = BankAction.close_account(acc)
      assert reason == {:account, :notempty}
      assert BankAccountInternal.fetch(acc.account_number)
    end

    test "with invalid data" do
      assert {:error, reason} = BankAction.close_account(Random.number())
      assert reason == {:account, :notfound}
    end
  end
end
