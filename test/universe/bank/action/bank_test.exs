defmodule Helix.Universe.Bank.Action.BankTest do

  use Helix.Test.Case.Integration

  import Helix.Test.Case.ID

  alias Helix.Entity.Model.Entity
  alias Helix.Network.Model.Connection
  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Universe.Bank.Action.Bank, as: BankAction
  alias Helix.Universe.Bank.Internal.BankAccount, as: BankAccountInternal
  alias Helix.Universe.Bank.Internal.BankTransfer, as: BankTransferInternal
  alias Helix.Universe.Bank.Model.BankAccount.PasswordRevealedEvent,
    as: BankAccountPasswordRevealedEvent
  alias Helix.Universe.Bank.Model.BankTokenAcquiredEvent
  alias Helix.Universe.Bank.Query.Bank, as: BankQuery

  alias Helix.Test.Account.Setup, as: AccountSetup
  alias Helix.Test.Universe.Bank.Setup, as: BankSetup
  alias Helix.Test.Universe.NPC.Helper, as: NPCHelper

  describe "start_transfer/4" do
    test "with valid data" do
      amount = 500
      {acc1, _} = BankSetup.account([balance: amount])
      {acc2, _} = BankSetup.account()
      {player, _} = AccountSetup.account([with_server: true])

      assert {:ok, transfer} =
        BankAction.start_transfer(acc1, acc2, amount, player)

      assert BankTransferInternal.fetch(transfer)
      assert BankAccountInternal.get_balance(acc1) == 0
      assert BankAccountInternal.get_balance(acc2) == 0
    end

    test "with insufficient funds" do
      amount = 500
      {acc1, _} = BankSetup.account([balance: 100])
      {acc2, _} = BankSetup.account()
      {player, _} = AccountSetup.account([with_server: true])

      assert {:error, {:funds, :insufficient}} =
        BankAction.start_transfer(acc1, acc2, amount, player)

      assert BankAccountInternal.get_balance(acc1) == 100
      assert BankAccountInternal.get_balance(acc2) == 0
    end
  end

  describe "complete_transfer/1" do
    test "with valid data" do
      amount = 100
      {transfer, %{acc1: account_from, acc2: account_to}} =
        BankSetup.transfer([amount: amount])

      assert :ok == BankAction.complete_transfer(transfer)

      refute BankTransferInternal.fetch(transfer)
      assert BankAccountInternal.get_balance(account_from) == 0
      assert BankAccountInternal.get_balance(account_to) == amount
    end

    test "with invalid data" do
      {fake_transfer, _} = BankSetup.fake_transfer()

      assert {:error, reason} = BankAction.complete_transfer(fake_transfer)
      assert reason == {:transfer, :notfound}
    end
  end

  describe "abort_transfer/1" do
    test "with valid data" do
      amount = 100
      {transfer, %{acc1: account_from, acc2: account_to}} =
        BankSetup.transfer([amount: amount])

      assert :ok == BankAction.abort_transfer(transfer)

      refute BankTransferInternal.fetch(transfer)
      assert BankAccountInternal.get_balance(account_from) == amount
      assert BankAccountInternal.get_balance(account_to) == 0
    end

    test "with invalid data" do
      {fake_transfer, _} = BankSetup.fake_transfer()
      assert {:error, reason} = BankAction.abort_transfer(fake_transfer)
      assert reason == {:transfer, :notfound}
    end
  end

  describe "open_account/2" do
    test "default case" do
      {player, _} = AccountSetup.account()
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
    test "closes the account" do
      {acc, _} = BankSetup.account()

      assert BankAccountInternal.fetch(acc.atm_id, acc.account_number)
      assert :ok == BankAction.close_account(acc)
      refute BankAccountInternal.fetch(acc.atm_id, acc.account_number)
    end

    test "refuses to close non-empty accounts" do
      {acc, _} = BankSetup.account([balance: 1])

      assert BankAccountInternal.fetch(acc.atm_id, acc.account_number)
      assert {:error, reason} = BankAction.close_account(acc)
      assert reason == {:account, :notempty}
      assert BankAccountInternal.fetch(acc.atm_id, acc.account_number)
    end

    test "with invalid data" do
      {fake_acc, _} = BankSetup.fake_account()
      assert {:error, reason} = BankAction.close_account(fake_acc)
      assert reason == {:account, :notfound}
    end
  end

  describe "generate_token/2" do
    test "creates a new token if none is found" do
      connection = Connection.ID.generate()
      entity = Entity.ID.generate()
      {acc, _} = BankSetup.account()

      assert {:ok, token_id, [e]} =
        BankAction.generate_token(acc, connection, entity)

      assert BankQuery.fetch_token(token_id)
      assert e == expected_token_event(token_id, acc, entity)
    end

    test "returns the token if it already exists" do
      connection = Connection.ID.generate()
      entity = Entity.ID.generate()
      {token, %{acc: acc}} = BankSetup.token([connection_id: connection])

      assert {:ok, token_id, [e]} =
        BankAction.generate_token(acc, connection, entity)

      assert token_id == token.token_id
      assert e == expected_token_event(token_id, acc, entity)
    end

    test "ignores existing tokens on different connections" do
      connection1 = Connection.ID.generate()
      connection2 = Connection.ID.generate()
      entity = Entity.ID.generate()
      {token, %{acc: acc}} = BankSetup.token([connection_id: connection1])

      assert {:ok, token_id, [e]} =
        BankAction.generate_token(acc, connection2, entity)

      refute token_id == token.token_id
      assert e == expected_token_event(token_id, acc, entity)

      # Two connections, two tokens
      assert BankQuery.fetch_token(token.token_id)
      assert BankQuery.fetch_token(token_id)
    end
  end

  defp expected_token_event(token_id, acc, entity_id) do
    %BankTokenAcquiredEvent{
      entity_id: entity_id,
      token_id: token_id,
      atm_id: acc.atm_id,
      account_number: acc.account_number
    }
  end

  describe "reveal_account_password/2" do
    test "password is revealed if correct input is entered" do
      {token, %{acc: acc}} = BankSetup.token()
      entity = Entity.ID.generate()

      assert {:ok, password, [e]} =
        BankAction.reveal_password(acc, token.token_id, entity)
      assert password == acc.password
      assert e == expected_revealed_event(acc, entity)
    end

    test "password is not revealed for non-existent token" do
      {fake_token, %{acc: acc}} = BankSetup.fake_token()
      fake_entity = Entity.ID.generate()

      assert {:error, reason} =
        BankAction.reveal_password(acc, fake_token.token_id, fake_entity)
      assert reason == {:token, :notfound}
    end

    test "password is not revealed for expired token" do
      {token, %{acc: acc}} = BankSetup.token([expired: true])
      entity = Entity.ID.generate()

      assert {:error, reason} =
        BankAction.reveal_password(acc, token.token_id, entity)
      assert reason == {:token, :notfound}
    end

    test "password is not revealed if token belongs to another account" do
      {token, _} = BankSetup.token()
      {acc, _} = BankSetup.account()
      entity = Entity.ID.generate()

      assert {:error, reason} =
        BankAction.reveal_password(acc, token.token_id, entity)
      assert reason == {:token, :notfound}
    end
  end

  defp expected_revealed_event(acc, entity_id) do
    %BankAccountPasswordRevealedEvent{
      entity_id: entity_id,
      account_number: acc.account_number,
      atm_id: acc.atm_id,
      password: acc.password
    }
  end
end
