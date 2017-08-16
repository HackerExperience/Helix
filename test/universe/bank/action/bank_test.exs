defmodule Helix.Universe.Bank.Action.BankTest do

  use Helix.Test.IntegrationCase

  import Helix.Test.IDCase

  alias Helix.Network.Model.Connection
  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Universe.Bank.Action.Bank, as: BankAction
  alias Helix.Universe.Bank.Internal.BankAccount, as: BankAccountInternal
  alias Helix.Universe.Bank.Internal.BankTransfer, as: BankTransferInternal
  alias Helix.Universe.Bank.Model.BankTokenAcquiredEvent
  alias Helix.Universe.Bank.Query.Bank, as: BankQuery

  alias HELL.TestHelper.Setup
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

      account_from =
        BankQuery.fetch_account(transfer.atm_from, transfer.account_from)
      account_to =
        BankQuery.fetch_account(transfer.atm_to, transfer.account_to)

      refute BankTransferInternal.fetch(transfer)
      assert BankAccountInternal.get_balance(account_from) == 0
      assert BankAccountInternal.get_balance(account_to) == amount
    end

    test "with invalid data" do
      fake_transfer = Setup.fake_bank_transfer()
      assert {:error, reason} = BankAction.complete_transfer(fake_transfer)
      assert reason == {:transfer, :notfound}
    end
  end

  describe "abort_transfer/1" do
    test "with valid data" do
      amount = 100
      transfer = Setup.bank_transfer([amount: amount])

      assert :ok == BankAction.abort_transfer(transfer)

      account_from =
        BankQuery.fetch_account(transfer.atm_from, transfer.account_from)
      account_to =
        BankQuery.fetch_account(transfer.atm_to, transfer.account_to)

      refute BankTransferInternal.fetch(transfer)
      assert BankAccountInternal.get_balance(account_from) == amount
      assert BankAccountInternal.get_balance(account_to) == 0
    end

    test "with invalid data" do
      fake_transfer = Setup.fake_bank_transfer()
      assert {:error, reason} = BankAction.abort_transfer(fake_transfer)
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
    test "closes the account" do
      acc = Setup.bank_account()

      assert BankAccountInternal.fetch(acc.atm_id, acc.account_number)
      assert :ok == BankAction.close_account(acc)
      refute BankAccountInternal.fetch(acc.atm_id, acc.account_number)
    end

    test "refuses to close non-empty accounts" do
      acc = Setup.bank_account([balance: 1])

      assert BankAccountInternal.fetch(acc.atm_id, acc.account_number)
      assert {:error, reason} = BankAction.close_account(acc)
      assert reason == {:account, :notempty}
      assert BankAccountInternal.fetch(acc.atm_id, acc.account_number)
    end

    test "with invalid data" do
      fake_acc = Setup.fake_bank_account()
      assert {:error, reason} = BankAction.close_account(fake_acc)
      assert reason == {:account, :notfound}
    end
  end

  describe "generate_token/2" do
    test "creates a new token if none is found" do
      acc = Setup.bank_account()
      connection = Connection.ID.generate()

      assert {:ok, token_id, [e]} = BankAction.generate_token(acc, connection)

      assert BankQuery.fetch_token(token_id)
      assert e == expected_token_event(token_id, acc)
    end

    test "returns the token if it already exists" do
      connection = Connection.ID.generate()
      token = Setup.bank_token([connection_id: connection])
      acc = BankQuery.fetch_account(token.atm_id, token.account_number)

      assert {:ok, token_id, [e]} = BankAction.generate_token(acc, connection)

      assert token_id == token.token_id
      assert e == expected_token_event(token_id, acc)
    end

    test "ignores existing tokens on different connections" do
      connection1 = Connection.ID.generate()
      connection2 = Connection.ID.generate()
      token = Setup.bank_token([connection_id: connection1])
      acc = BankQuery.fetch_account(token.atm_id, token.account_number)

      assert {:ok, token_id, [e]} = BankAction.generate_token(acc, connection2)

      refute token_id == token.token_id
      assert e == expected_token_event(token_id, acc)

      # Two connections, two tokens
      assert BankQuery.fetch_token(token.token_id)
      assert BankQuery.fetch_token(token_id)
    end
  end

  defp expected_token_event(token_id, acc) do
    %BankTokenAcquiredEvent{
      token_id: token_id,
      atm_id: acc.atm_id,
      account_number: acc.account_number
    }
  end
end
