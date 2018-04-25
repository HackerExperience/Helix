defmodule Helix.Universe.Bank.Henforcer.BankTest do

  use Helix.Test.Case.Integration

  import Helix.Test.Henforcer.Macros

  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Universe.Bank.Henforcer.Bank, as: BankHenforcer
  alias Helix.Universe.Bank.Query.Bank, as: BankQuery

  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Server.Helper, as: ServerHelper
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Universe.Bank.Helper, as: BankHelper
  alias Helix.Test.Universe.Bank.Setup, as: BankSetup
  alias Helix.Test.Entity.Setup, as: EntitySetup

  @internet_id NetworkHelper.internet_id()

  describe "account_exists?/1" do
    test "accepts when account exists" do
      # Setups a BankAccount for testing
      bank_acc = BankSetup.account!()

      # Asserts that henforcer accepts when account exists
      assert {true, relay} =
        BankHenforcer.account_exists?(bank_acc.atm_id, bank_acc.account_number)

      # Asserts that bank account on relay is the same
      # as created before
      assert relay.bank_account == bank_acc

      # Assert that relay only contains :bank_account key
      assert_relay relay, [:bank_account]
    end

    test "rejects when account does not exist" do
      # Asserts that henforcer returns error when account does not exist
      assert {false, reason, _} =
        BankHenforcer.account_exists?(
          BankHelper.atm_id(), BankHelper.account_number()
        )

      # Asserts that the reason for failing is `{:bank_account, :not_found}`
      assert reason == {:bank_account, :not_found}
    end
  end

  describe "password_valid?/2" do
    test "accepts when password is the same as the bank account's password" do
      # Setups a BankAccount for testing
      bank_acc = BankSetup.account!()

      # Asserts that henforcer accepts when passwords match
      assert {true, relay} =
        BankHenforcer.password_valid?(bank_acc, bank_acc.password)

      # Asserts that relay's password is the same as BankAccounts's Password
      assert relay.password == bank_acc.password

      # Asserts that relay only contains the :password key
      assert_relay relay, [:password]
    end

    test "rejects when password is not the same as the bank account's password" do
      # Setups a BankAccount for testing
      bank_acc = BankSetup.account!()

      # Asserts that henforcer returns error when password does not match
      assert {false, reason, _} =
        BankHenforcer.password_valid?(bank_acc, BankHelper.password())

      # Asserts that the reason for failing is `{:password, :invalid}`
      assert reason == {:password, :invalid}
    end
  end

  describe "can_join_password?/4" do
    test "accepts when account and entity exists and the password is valid" do
      # Setups an Entity for testing
      {entity, _} = EntitySetup.entity()
      entity_id = entity.entity_id

      # Setups a BankAccount for testing
      bank_acc = BankSetup.account!()
      atm_id = bank_acc.atm_id
      account_number = bank_acc.account_number
      password = bank_acc.password

      # Asserts that henforcer accepts when account and entity exists and
      # the passwords match
      assert {true, relay} =
        BankHenforcer.can_join_password?(
            atm_id,
            account_number,
            password,
            entity_id
            )

      # Asserts that relay information is correct
      assert relay.bank_account == bank_acc
      assert relay.password == password
      assert relay.entity == entity

      # Asserts that relay only contains desired keys
      assert_relay relay, [:bank_account, :password, :entity]
    end

    test "rejects when account does not exists" do
      # Setups an Entity for testing
      {entity, _} = EntitySetup.entity()

      # Setups fake BankAccount Values
      atm_id = BankHelper.atm_id()
      account_number = BankHelper.account_number
      password = BankHelper.password
      entity_id = entity.entity_id

      # Asserts that henforcer rejects trying to join a account that does not
      # exist
      assert {false, reason, _} =
        BankHenforcer.can_join_password?(
          atm_id,
          account_number,
          password,
          entity_id
          )

      # Asserts that reason to fail is `{:bank_account, :not_found}`
      # Because the account does't exists
      assert reason == {:bank_account, :not_found}
    end

    test "rejects when entity does not exists" do
      # Setups BankAccount for testing
      bank_acc = BankSetup.account!()
      atm_id = bank_acc.atm_id
      account_number = bank_acc.account_number
      password = bank_acc.password

      # Generates an entity id that not exists on database
      entity_id = EntitySetup.id()

      # Asserts that henforcer rejects when trying to join with a entity that
      # does not exist
      assert {false, reason, _} =
        BankHenforcer.can_join_password?(
          atm_id,
          account_number,
          password,
          entity_id
          )

      # Asserts that reason for fail is `{:entity, :not_found}`
      assert reason == {:entity, :not_found}
    end

    test "rejects when password does not match" do
      # Setups an Entity and a BankAccount for testing
      {entity, _} = EntitySetup.entity()
      bank_acc = BankSetup.account!()
      entity_id = entity.entity_id
      atm_id = bank_acc.atm_id
      account_number = bank_acc.account_number

      # Generates a password that not match BankAccount's password
      password = BankHelper.password()

      # Asserts the henforcer rejects when passwords does not match
      assert {false, reason, _} =
        BankHenforcer.can_join_password?(
          atm_id,
          account_number,
          password,
          entity_id
          )

      # Asserts that reason for fail is `{:password, :invalid}`
      assert reason == {:password, :invalid}
    end
  end

  describe "can_join_token?/4" do
    test "accepts when account and entity exists and the token is valid" do
      # Setups an Entity for testing
      {entity, _} = EntitySetup.entity()
      entity_id = entity.entity_id

      # Setups a BankAccount for testing
      bank_acc = BankSetup.account!()
      atm_id = bank_acc.atm_id
      account_number = bank_acc.account_number

      # Setups a Token for testing
      token = BankSetup.token!(acc: bank_acc)

      # Asserts that accepts when both Entity, Account and Token are valid.
      assert {true, relay} =
        BankHenforcer.can_join_token?(
          atm_id,
          account_number,
          token.token_id,
          entity_id
        )

      # Asserts that token is the same as the token created before.
      assert relay.token.token_id == token.token_id
      assert relay.token.atm_id == atm_id
      assert relay.token.account_number == account_number

      # Asserts that relay's account still the same as when created.
      assert relay.bank_account.atm_id == atm_id
      assert relay.bank_account.account_number == account_number

      # Asserts that relay's entity still the same as when created.
      assert relay.entity == entity

      # Asserts that relay only contains the :token key.
      assert_relay relay, [:token, :bank_account, :entity]
    end

    test "rejects when token is not related to given account" do
      # Setups an Entity for testing
      {entity, _} = EntitySetup.entity()
      entity_id = entity.entity_id

      # Setups a BankAccount for trying to join
      bank_acc = BankSetup.account!()

      # Setups a BankAccount for generate token
      bank_acc_token = BankSetup.account!()

      # Gets the trying to join BankAccount information
      atm_id = bank_acc.atm_id
      account_number = bank_acc.account_number

      # Setup a Token for the `bank_acc_token` BankAccount
      token = BankSetup.token!(acc: bank_acc_token)

      # Asserts that henforcer rejects because the given token
      # does not belongs for the BankAccount used to try the join
      assert {false, reason, _} =
        BankHenforcer.can_join_token?(
          atm_id,
          account_number,
          token.token_id,
          entity_id
        )

      # Asserts that the reason is `{:token, :not_belongs}`
      assert reason == {:token, :not_belongs}
    end

    test "rejects when token is expired" do
      # Setups an Entity for testing
      {entity, _} = EntitySetup.entity()
      entity_id = entity.entity_id

      # Setups a BankAccount for testing
      bank_acc = BankSetup.account!()
      atm_id = bank_acc.atm_id
      account_number = bank_acc.account_number

      # Setups an expired Token
      token = BankSetup.token!(acc: bank_acc, expired: true)
      token_id = token.token_id

      # Asserts that henforcer rejects because the token is expired
      assert {false, reason, _} =
        BankHenforcer.can_join_token?(
          atm_id,
          account_number,
          token_id,
          entity_id
        )

      # Asserts that the reason for failing is `{:token, :expired}`
      assert reason == {:token, :expired}
    end

    test "rejects when token does not exists" do
      # Setups an Entity for testing
      {entity, _} = EntitySetup.entity()
      entity_id = entity.entity_id

      # Setups a BankAccount for testing
      bank_acc = BankSetup.account!()
      atm_id = bank_acc.atm_id
      account_number = bank_acc.account_number

      # Setups an token id that does not exist
      token_id = Ecto.UUID.generate()

      # Asserts that henforcer rejects because token does not exist
      assert {false, reason, _} =
        BankHenforcer.can_join_token?(
          atm_id,
          account_number,
          token_id,
          entity_id
        )

      # Asserts that the failing reason is `{:token, :not_found}`
      assert reason == {:token, :not_found}
    end
  end

  describe "owns_account?/2" do
    test "accepts when the entity owns the account" do
      # Setups an Entity and a BankAccount that belongs to that Entity
      {entity, _} = EntitySetup.entity()
      bank_acc = BankSetup.account!(owner_id: entity.entity_id)

      # Asserts that henforcer accepts because `bank_acc` belongs to `entity`
      assert {true, relay} =
        BankHenforcer.owns_account?(entity, bank_acc)

      # Asserts that relay's BankAccount is the same as created BankAccount
      assert relay.bank_account == bank_acc

      # Asserts that relay only contains :bank_account key
      assert_relay relay, [:bank_account]
    end

    test "rejects when the entity not owns the account" do
      # Setups an Entity for testing
      {entity, _} = EntitySetup.entity()

      # Setups a BankAccount which not belongs to that entity
      bank_acc = BankSetup.account!()

      # Asserts that henforcer rejects because entity does not own the
      # BankAccount
      assert{false, reason, _} =
        BankHenforcer.owns_account?(entity, bank_acc)

      # Asserts that reason for failing is `{:bank_account, :not_found}`
      assert reason == {:bank_account, :not_belongs}
    end
  end

  describe "is_empty?/1" do
    test "accepts when the account has no funds" do
      # Setups a BankAccount for testing
      bank_acc = BankSetup.account!()

      # Asserts that henforcer accepts because the BankAccount has no funds
      assert {true, relay} =
        BankHenforcer.is_empty?(bank_acc)

      # Asserts that the relay's BankAccount is the same as `bank_acc`
      assert relay.bank_account == bank_acc

      # Asserts that relay only contains :bank_account key
      assert_relay relay, [:bank_account]
    end

    test "rejects when account has funds" do
      # Setups an BankAccount that has funds
      bank_acc = BankSetup.account!(balance: 500)

      # Asserts that henforcer rejects because the BankAccount has funds
      assert {false, reason, _} =
        BankHenforcer.is_empty?(bank_acc)

      # Asserts that reason for failing is `{:bank_account, :not_empty}`
      assert reason == {:bank_account, :not_empty}
    end
  end

  describe "has_enough_funds?/2" do
    test "accepts when account has enough funds" do
      # Setups a BankAccount that has enough funds for tranfer
      bank_acc = BankSetup.account!(balance: 500)

      # Asserts that henforcer accepts because the BankAccount has the required
      # funds to do the transfer
      assert {true, relay} =
        BankHenforcer.has_enough_funds?(bank_acc, 500)

      # Asserts that relay's amount is the same as given
      assert relay.amount == 500

      # Asserts that relay only contains :amount key
      assert_relay relay, [:amount]
    end

    test "rejects when account has not enough funds" do
      # Setups a BankAccount that does not have enough funds
      bank_acc = BankSetup.account!(balance: 500)

      # Asserts that henforcer reject because the BankAccount
      # has no enough funds
      assert {false, reason, _} =
        BankHenforcer.has_enough_funds?(bank_acc, 501)

      # Asserts that reason for failing is `{:bank_account, :no_funds}`
      assert reason == {:bank_account, :no_funds}
    end
  end

  describe "can_transfer?/5" do
    test "accepts when everything is ok" do
      # Setups a BankAccount to send money
      snd_acc = BankSetup.account!(balance: 500)
      snd_acc_id = {snd_acc.atm_id, snd_acc.account_number}

      # Setups a BankAccount to receive money
      rcv_acc = BankSetup.account!()

      # Gets the receiving BankAccount's ATM server information
      atm = ServerQuery.fetch(rcv_acc.atm_id)
      atm_ip = ServerHelper.get_ip(atm)
      atm_nip = {@internet_id, atm_ip}

      # Asserts that henforcer accepts because both
      # BankAccount exists, the sending BankAccount has enough money,
      # the ATM exists and is a bank
      assert {true, relay} =
        BankHenforcer.can_transfer?(
        atm_nip,
        rcv_acc.account_number,
        snd_acc_id,
        500,
        snd_acc.password
      )

      # Asserts that relay value are all correct
      assert relay.amount == 500
      assert relay.password == snd_acc.password
      assert relay.to_account == rcv_acc

      # Asserts that relay only contains the neccessary keys
      assert_relay relay, [:amount, :password, :to_account]
    end
  end

  describe "is_a_bank?" do
    test "accepts when the given server is a bank" do
      # Setups a BankAccount for getting an atm_id that
      # really comes from a bank
      bank_acc = BankSetup.account!()

      # Asserts that henforcer accepts because the atm_id belongs to a bank
      assert {true, relay} =
        BankHenforcer.is_a_bank?(bank_acc.atm_id)

      # Asserts that relay values are correct
      assert relay.atm == BankQuery.fetch_atm(bank_acc.atm_id)

      # Asserts that relay only contains needed values
      assert relay, [:atm]
    end

    test "rejects when the given server is not a bank" do
      # Setups a Server that is not a bank
      server = ServerSetup.server!()

      # Asserts the henforcer rejects because the server is not a bank
      assert {false, reason, _} =
        BankHenforcer.is_a_bank?(server.server_id)

      # Asserts that reason for failing is `{:atm, :not_a_bank}`
      assert reason == {:atm, :not_a_bank}
    end
  end
end
