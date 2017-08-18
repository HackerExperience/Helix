defmodule Helix.Universe.Bank.Query.BankTest do

  use Helix.Test.Case.Integration

  alias Helix.Universe.Bank.Query.Bank, as: BankQuery
  alias Helix.Universe.Bank.Internal.BankAccount, as: BankAccountInternal

  alias Helix.Test.Account.Setup, as: AccountSetup
  alias Helix.Test.Universe.Bank.Setup, as: BankSetup

  describe "fetch_account/1" do
    test "with valid account" do
      {acc, _} = BankSetup.account()

      acc2 = BankQuery.fetch_account(acc.atm_id, acc.account_number)
      assert acc2 == acc
    end
  end

  describe "get_account_balance/1" do
    test "with empty account" do
      {acc, _} = BankSetup.account()

      assert BankQuery.get_account_balance(acc) == 0
    end

    test "with subsequent deposits" do
      {acc, _} = BankSetup.account([balance: 100])

      assert BankQuery.get_account_balance(acc) == 100

      BankAccountInternal.deposit(acc, 50)
      assert BankQuery.get_account_balance(acc) == 150

      BankAccountInternal.withdraw(acc, 50)
      assert BankQuery.get_account_balance(acc) == 100
    end
  end

  describe "get_accounts/1" do
    test "with zero, one or many accounts" do
      {owner, _} = AccountSetup.account()

      # Zero accounts
      assert [] == BankQuery.get_accounts(owner)

      # One account
      {acc1, _} = BankSetup.account([owner_id: owner.account_id])
      assert [acc1] == BankQuery.get_accounts(owner)

      # Many accounts
      {acc2, _} = BankSetup.account([owner_id: owner.account_id])
      {acc3, _} = BankSetup.account([owner_id: owner.account_id])
      assert [acc1, acc2, acc3] == BankQuery.get_accounts(owner)
    end
  end

  describe "get_total_funds/1" do
    test "with zero, one or many accounts" do
      {owner, _} = AccountSetup.account()

      # Zero accounts
      assert 0 == BankQuery.get_total_funds(owner)

      # One account
      BankSetup.account([owner_id: owner.account_id, balance: 100])
      assert 100 == BankQuery.get_total_funds(owner)

      # Many accounts
      BankSetup.account([owner_id: owner.account_id, balance: 50])
      assert 150 == BankQuery.get_total_funds(owner)

      BankSetup.account([owner_id: owner.account_id, balance: 1])
      assert 151 == BankQuery.get_total_funds(owner)

      # Totally unrelated account
      BankSetup.account([balance: 1000])
      assert 151 == BankQuery.get_total_funds(owner)
    end
  end
end
