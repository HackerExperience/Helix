defmodule Helix.Universe.Bank.Internal.BankAccountTest do

  use Helix.Test.IntegrationCase

  import Helix.Test.IDCase

  alias HELL.TestHelper.Random
  alias HELL.TestHelper.Setup
  alias Helix.Universe.Bank.Internal.BankAccount, as: BankAccountInternal
  alias Helix.Universe.NPC.Helper, as: NPCHelper

  describe "fetch/1" do
    test "it works" do
      acc = Setup.bank_account()

      acc2 = BankAccountInternal.fetch(acc.account_number)

      assert acc.account_number == acc2.account_number
      assert_id acc.bank_id, acc2.bank_id
      assert_id acc.atm_id, acc2.atm_id
      assert acc.balance == acc2.balance
    end
  end

  describe "get_accounts/1" do
    test "it works" do
      {_, player} = Setup.server()
      player_id = player.account_id

      # Player does not have any bank accounts yet
      assert [] == BankAccountInternal.get_accounts(player_id)

      # Now she has one
      acc = Setup.bank_account([owner_id: player_id])
      assert [acc] == BankAccountInternal.get_accounts(player_id)

      # And now with multiple accounts.
      # Note that we can only compare these two lists because `get_accounts`
      # returns the accounts ordered by creation date.
      acc2 = Setup.bank_account([owner_id: player_id])
      acc3 = Setup.bank_account([owner_id: player_id])
      accounts = BankAccountInternal.get_accounts(player_id)
      assert accounts == [acc, acc2, acc3]
    end
  end

  describe "get_balance/1" do
    test "with valid data" do
      acc = Setup.bank_account()

      balance = BankAccountInternal.get_balance(acc.account_number)
      assert balance == acc.balance
    end

    test "with non-existing account" do
      assert BankAccountInternal.get_balance(1234) == 0
    end
  end

  describe "get_total_funds/1" do
    test "it works" do
      {_, player} = Setup.server()
      player_id = player.account_id

      refute BankAccountInternal.get_total_funds(player_id)

      acc1 = Setup.bank_account([owner_id: player_id])
      acc2 = Setup.bank_account([owner_id: player_id])

      BankAccountInternal.deposit(acc1, 1234)
      BankAccountInternal.deposit(acc2, 200)

      balance = BankAccountInternal.get_total_funds(player_id)
      assert balance == 1434
    end
  end

  describe "create/1" do
    test "it works" do
      bank = NPCHelper.bank()
      atm_id = Enum.random(bank.servers).id
      owner_id = Random.pk()

      params = %{
        bank_id: bank.id,
        atm_id: atm_id,
        owner_id: owner_id
      }

      assert {:ok, acc} = BankAccountInternal.create(params)
      assert_id acc.atm_id, atm_id
      assert_id acc.bank_id, bank.id
      assert_id acc.owner_id, owner_id
      assert acc.balance == 0
      assert is_number(acc.account_number)
      assert acc.creation_date
    end
  end

  describe "deposit/2" do
    test "it works" do
      acc = Setup.bank_account()
      number = acc.account_number

      # Nothing initially
      assert BankAccountInternal.get_balance(number) == 0

      # Deposit 1.01
      assert {:ok, acc2} = BankAccountInternal.deposit(acc, 101)
      assert acc2.balance == 101
      assert BankAccountInternal.get_balance(number) == 101

      # Deposit 0.01
      assert {:ok, acc3} = BankAccountInternal.deposit(acc2, 1)
      assert acc3.balance == 102
      assert BankAccountInternal.get_balance(number) == 102
    end
  end

  describe "withdraw/2" do
    test "it works" do
      acc = Setup.bank_account()
      number = acc.account_number

      # Deposit something
      BankAccountInternal.deposit(acc, 1000)

      # Withdraw 1.00
      assert {:ok, acc2} = BankAccountInternal.withdraw(acc, 100)
      assert acc2.balance == 900
      assert BankAccountInternal.get_balance(number) == 900

      # Withdraw 1.50
      assert {:ok, acc3} = BankAccountInternal.withdraw(acc2, 150)
      assert acc3.balance == 750
      assert BankAccountInternal.get_balance(number) == 750
    end

    test "with insufficient funds" do
      acc = Setup.bank_account()

      assert {:error, reason} = BankAccountInternal.withdraw(acc, 5000)
      assert reason == {:funds, :insufficient}
    end
  end

  describe "change_password/1" do
    test "it changes the password" do
      acc = Setup.bank_account()

      assert {:ok, acc2} = BankAccountInternal.change_password(acc)

      refute acc.password == acc2.password
    end
  end

  describe "delete/1" do
    test "it deletes the account" do
      acc = Setup.bank_account()

      assert BankAccountInternal.fetch(acc.account_number)
      BankAccountInternal.delete(acc)
      refute BankAccountInternal.fetch(acc.account_number)
    end
  end
end
