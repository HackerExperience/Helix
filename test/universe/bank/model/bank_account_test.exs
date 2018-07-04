defmodule Helix.Universe.Bank.Model.BankAccountTest do

  use ExUnit.Case, async: true

  alias Helix.Universe.Bank.Model.BankAccount

  alias Helix.Test.Account.Helper, as: AccountHelper
  alias Helix.Test.Server.Helper, as: ServerHelper
  alias Helix.Test.Universe.NPC.Helper, as: NPCHelper

  describe "change_password/1" do
    test "changes password" do
      acc =
        %BankAccount{
          bank_id: NPCHelper.id(),
          atm_id: ServerHelper.id(),
          password: "1234",
          owner_id: AccountHelper.id(),
          balance: 1234
        }

      acc2 = BankAccount.change_password(acc)

      assert acc2.valid?
      assert Ecto.Changeset.get_change(acc2, :password)
    end
  end

  describe "deposit/1" do
    test "increases the account balance" do
      acc =
        %BankAccount{
          bank_id: NPCHelper.id(),
          atm_id: ServerHelper.id(),
          password: "1234",
          owner_id: AccountHelper.id(),
          balance: 1000
        }

      acc2 = BankAccount.deposit(acc, 3001)
      assert acc2.valid?
      assert 4001 == Ecto.Changeset.get_change(acc2, :balance)
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
    test "decreases the account balance" do
      acc =
        %BankAccount{
          bank_id: NPCHelper.id(),
          atm_id: ServerHelper.id(),
          password: "1234",
          owner_id: AccountHelper.id(),
          balance: 1000
        }

      acc2 = BankAccount.withdraw(acc, 1)
      assert acc2.valid?
      assert 999 == Ecto.Changeset.get_change(acc2, :balance)
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
