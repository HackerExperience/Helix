defmodule Helix.Universe.Bank.Model.BankAccountTest do

  use Helix.Test.IntegrationCase

  alias HELL.TestHelper.Random
  alias Helix.Universe.Bank.Model.BankAccount

  describe "change_password/1" do
    test "it changes password" do
      acc =
        %BankAccount{
          bank_id: Random.pk(),
          atm_id: Random.pk(),
          password: "1234",
          owner_id: Random.pk(),
          balance: 1234
        }

      acc2 = BankAccount.change_password(acc)

      assert acc2.valid?
      assert Ecto.Changeset.get_change(acc2, :password)
    end
  end

  describe "balance_operation/3" do
    test "it adds" do
      current = 100
      amount = 37
      sum = BankAccount.balance_operation(:add, current, amount)
      assert sum == 137
    end

    test "it subs" do
      current = 100
      amount = 37
      sub = BankAccount.balance_operation(:sub, current, amount)
      assert sub == 63
    end

    test "it blows when subtracting more than it should" do
      assert_raise RuntimeError, fn ->
        BankAccount.balance_operation(:sub, 10, 11)
      end
    end
  end

  describe "deposit/1" do
    test "it deposits!" do
      acc =
        %BankAccount{
          bank_id: Random.pk(),
          atm_id: Random.pk(),
          password: "1234",
          owner_id: Random.pk(),
          balance: 1000
        }

      acc2 = BankAccount.deposit(acc, 3001)
      assert acc2.valid?
      assert Ecto.Changeset.get_change(acc2, :balance) == 4001
    end

    test "with invalid data" do
      assert_raise FunctionClauseError, fn ->
        BankAccount.deposit(%BankAccount{}, 0)
      end
      assert_raise FunctionClauseError, fn ->
        BankAccount.deposit(%BankAccount{}, -1)
      end
    end
  end

  describe "withdraw/1" do
    test "it withdraws!" do
      acc =
        %BankAccount{
          bank_id: Random.pk(),
          atm_id: Random.pk(),
          password: "1234",
          owner_id: Random.pk(),
          balance: 1000
        }

      acc2 = BankAccount.withdraw(acc, 1)
      assert acc2.valid?
      assert Ecto.Changeset.get_change(acc2, :balance) == 999
    end

    test "with invalid data" do
      assert_raise FunctionClauseError, fn ->
        BankAccount.withdraw(%BankAccount{}, 0)
      end
      assert_raise FunctionClauseError, fn ->
        BankAccount.withdraw(%BankAccount{}, -1)
      end
    end
  end
end
