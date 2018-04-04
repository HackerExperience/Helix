defmodule Helix.Universe.Bank.Henforcer.BankTest do

  use Helix.Test.Case.Integration

  import Helix.Test.Henforcer.Macros

  alias Helix.Universe.Bank.Henforcer.Bank, as: BankHenforcer

  alias Helix.Test.Universe.Bank.Helper, as: BankHelper
  alias Helix.Test.Universe.Bank.Setup, as: BankSetup
  alias Helix.Test.Entity.Setup, as: EntitySetup
  alias Helix.Test.Entity.Helper, as: EntityHelper

  describe "account_exists?/1" do
    test "accepts when account exists" do
      bank_acc = BankSetup.account!()

      assert {true, relay} =
        BankHenforcer.account_exists?(bank_acc.atm_id, bank_acc.account_number)

      assert relay.bank_account == bank_acc

      assert_relay relay, [:bank_account]
    end

    test "rejects when account does not exist" do
      assert {false, reason, _} =
        BankHenforcer.account_exists?(
          BankHelper.atm_id(), BankHelper.account_number()
        )

      assert reason == {:bank_account, :not_found}
    end
  end
  describe "password_valid?/2" do
    test "accepts when password is the same as the bank account's password" do
      bank_acc = BankSetup.account!()

      assert {true, relay} =
        BankHenforcer.password_valid?(bank_acc, bank_acc.password)

      assert relay.password == bank_acc.password

      assert_relay relay, [:password]
    end
    test "rejects when password is not the same as the bank account's password" do
      bank_acc = BankSetup.account!()

      assert {false, reason, _} =
        BankHenforcer.password_valid?(bank_acc, BankHelper.password())

      assert reason == {:password, :invalid}

    end
  end
  describe "can_join?/4" do
    test "accepts when account and entity exists and the password is valid" do
      {entity, _} = EntitySetup.entity()

      bank_acc = BankSetup.account!()
      atm_id = bank_acc.atm_id
      account_number = bank_acc.account_number
      password = bank_acc.password
      entity_id = entity.entity_id

      assert {true, relay} =
        BankHenforcer.can_join?(atm_id, account_number, password, entity_id)

      assert relay.bank_account == bank_acc
      assert relay.password == password
      assert relay.entity == entity

      assert_relay relay, [:bank_account, :password, :entity]
    end
    test "rejects when account does not exists" do
      {entity, _} = EntitySetup.entity()

      atm_id = BankHelper.atm_id()
      account_number = BankHelper.account_number
      password = BankHelper.password
      entity_id = entity.entity_id

      assert {false, reason, _} =
        BankHenforcer.can_join?(atm_id, account_number, password, entity_id)

      assert reason == {:bank_account, :not_found}

    end
    test "rejects when entity does not exists" do
      bank_acc = BankSetup.account!()

      atm_id = bank_acc.atm_id
      account_number = bank_acc.account_number
      password = bank_acc.password
      entity_id = EntitySetup.id()

      assert {false, reason, _} =
        BankHenforcer.can_join?(atm_id, account_number, password, entity_id)

      assert reason == {:entity, :not_found}
    end
    test "rejects when password does not match" do
      {entity, _} = EntitySetup.entity()
      bank_acc = BankSetup.account!()

      entity_id = entity.entity_id
      atm_id = bank_acc.atm_id
      account_number = bank_acc.account_number
      password = BankHelper.password()

      assert {false, reason, _} =
        BankHenforcer.can_join?(atm_id, account_number, password, entity_id)

      assert reason == {:password, :invalid}

    end
  end
end
