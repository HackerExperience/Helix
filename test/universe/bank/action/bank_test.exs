defmodule Helix.Universe.Bank.Action.BankTest do

  use Helix.Test.Case.Integration

  import Helix.Test.Case.ID

  alias Helix.Entity.Model.Entity
  alias Helix.Network.Model.Connection
  alias Helix.Network.Query.Tunnel, as: TunnelQuery
  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Universe.Bank.Action.Bank, as: BankAction
  alias Helix.Universe.Bank.Internal.BankAccount, as: BankAccountInternal
  alias Helix.Universe.Bank.Internal.BankTransfer, as: BankTransferInternal
  alias Helix.Universe.Bank.Query.Bank, as: BankQuery

  alias Helix.Test.Account.Setup, as: AccountSetup
  alias Helix.Test.Event.Setup, as: EventSetup
  alias Helix.Test.Network.Setup, as: NetworkSetup
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Universe.NPC.Helper, as: NPCHelper
  alias Helix.Test.Universe.Bank.Helper, as: BankHelper
  alias Helix.Test.Universe.Bank.Setup, as: BankSetup

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
      {bank, _} = NPCHelper.bank()

      atm =
        bank
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
      entity_id = Entity.ID.generate()
      {acc, _} = BankSetup.account()

      assert {:ok, token, [e]} =
        BankAction.generate_token(acc, connection, entity_id)

      assert BankQuery.fetch_token(token.token_id)
      assert e == EventSetup.Bank.token_acquired(token.token_id, acc, entity_id)
    end

    test "returns the token if it already exists" do
      connection = Connection.ID.generate()
      entity_id = Entity.ID.generate()
      {gen_token, %{acc: acc}} = BankSetup.token([connection_id: connection])

      assert {:ok, db_token, [event]} =
        BankAction.generate_token(acc, connection, entity_id)

      assert db_token.token_id == gen_token.token_id
      assert event ==
        EventSetup.Bank.token_acquired(db_token.token_id, acc, entity_id)
    end

    test "ignores existing tokens on different connections" do
      connection1 = Connection.ID.generate()
      connection2 = Connection.ID.generate()
      entity_id = Entity.ID.generate()
      {gen_token, %{acc: acc}} = BankSetup.token([connection_id: connection1])

      assert {:ok, db_token, [event]} =
        BankAction.generate_token(acc, connection2, entity_id)

      refute db_token.token_id == gen_token.token_id
      assert event ==
        EventSetup.Bank.token_acquired(db_token.token_id, acc, entity_id)

      # Two connections, two tokens
      assert BankQuery.fetch_token(gen_token.token_id)
      assert BankQuery.fetch_token(db_token.token_id)
    end
  end

  describe "reveal_account_password/2" do
    test "password is revealed if correct input is entered" do
      {token, %{acc: acc}} = BankSetup.token()
      entity_id = Entity.ID.generate()

      assert {:ok, password, [e]} =
        BankAction.reveal_password(acc, token.token_id, entity_id)
      assert password == acc.password
      assert e == EventSetup.Bank.password_revealed(acc, entity_id)
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
      entity_id = Entity.ID.generate()

      assert {:error, reason} =
        BankAction.reveal_password(acc, token.token_id, entity_id)
      assert reason == {:token, :notfound}
    end

    test "password is not revealed if token belongs to another account" do
      {token, _} = BankSetup.token()
      {acc, _} = BankSetup.account()
      entity_id = Entity.ID.generate()

      assert {:error, reason} =
        BankAction.reveal_password(acc, token.token_id, entity_id)
      assert reason == {:token, :notfound}
    end
  end

  describe "login_password/3" do
    test "login is successful when password is correct" do
      {acc, _} = BankSetup.account()
      entity_id = Entity.ID.generate()

      {:ok, _, [e]} = BankAction.login_password(acc, acc.password, entity_id)
      assert e == EventSetup.Bank.login(acc, entity_id)
    end

    test "login fails with invalid password" do
      {acc, _} = BankSetup.account()
      entity_id = Entity.ID.generate()

      refute BankAction.login_password(acc, "incorrect_password", entity_id)
    end
  end

  describe "login_token/3" do
    test "login is successful when token is valid and matches the account" do
      {token, %{acc: acc}} = BankSetup.token()
      entity_id = Entity.ID.generate()

      {:ok, _, [e]} = BankAction.login_token(acc, token.token_id, entity_id)
      assert e == EventSetup.Bank.login(acc, entity_id, token.token_id)
    end

    test "login fails when given token belongs to a different account" do
      {acc, _} = BankSetup.account()
      {token, _} = BankSetup.token()
      entity_id = Entity.ID.generate()

      refute BankAction.login_token(acc, token.token_id, entity_id)
    end

    test "login fails when given token is expired" do
      {token, %{acc: acc}} = BankSetup.token([expired: true])
      entity_id = Entity.ID.generate()

      refute BankAction.login_token(acc, token.token_id, entity_id)
    end
  end

  describe "logout/2" do
    test "`bank_login` connection is successfully closed" do
      {gateway, _} = ServerSetup.server()
      {acc, _} = BankSetup.account()

      {tunnel, _} =
        NetworkSetup.tunnel(
          [gateway_id: gateway.server_id, target_id: acc.atm_id])

      tunnel_id = tunnel.tunnel_id

      conn_meta = generate_bank_login_meta(acc)

      {bank_connection, _} =
        NetworkSetup.connection(
          [tunnel_id: tunnel_id, type: :bank_login, meta: conn_meta])

      # Ensure bank connection really exists
      assert TunnelQuery.fetch_connection(bank_connection.connection_id)

      assert [event] = BankAction.logout(acc, gateway.server_id)

      # Look ma, no longer there.
      refute TunnelQuery.fetch_connection(bank_connection.connection_id)

      # Ensure spilled event is the one expected
      assert event == EventSetup.Network.connection_closed(bank_connection)
    end

    test "unrelated connections are not removed" do
      {player1, _} = ServerSetup.server()
      {player2, _} = ServerSetup.server()

      # Note: enforce different ATMs for each account otherwise we'd have to
      # verify if the tunnel already exists before creating it.
      {acc1, _} = BankSetup.account([atm_seq: 1])
      {acc2, _} = BankSetup.account([atm_seq: 2])
      {acc3, _} = BankSetup.account([atm_seq: 3])

      # Description of the context:
      # There are 2 players and three bank accounts.
      # - Player 1 is connected on accounts 1 and 2
      # - Player 2 is connected on accounts 1 and 3
      # Player 1 will logout from account 1
      # - Login of player 1 on account 2 should remain unchanged
      # - Login of player 2 on accounts 1 and 3 should remain unchanged
      # Just take my word for it and skip to the "CONTINUE HERE" below.
      {tunnel_p1a1, _} =
        NetworkSetup.tunnel(
          [gateway_id: player1.server_id, target_id: acc1.atm_id])
      {tunnel_p1a2, _} =
        NetworkSetup.tunnel(
          [gateway_id: player1.server_id, target_id: acc2.atm_id])
      {tunnel_p2a1, _} =
        NetworkSetup.tunnel(
          [gateway_id: player2.server_id, target_id: acc1.atm_id])
      {tunnel_p2a3, _} =
        NetworkSetup.tunnel(
          [gateway_id: player2.server_id, target_id: acc3.atm_id])

      tid_p1a1 = tunnel_p1a1.tunnel_id
      tid_p1a2 = tunnel_p1a2.tunnel_id
      tid_p2a1 = tunnel_p2a1.tunnel_id
      tid_p2a3 = tunnel_p2a3.tunnel_id

      meta_a1 = generate_bank_login_meta(acc1)
      meta_a2 = generate_bank_login_meta(acc2)
      meta_a3 = generate_bank_login_meta(acc3)

      {conn_p1a1, _} =
        NetworkSetup.connection(
          [tunnel_id: tid_p1a1, type: :bank_login, meta: meta_a1])
      {conn_p1a2, _} =
        NetworkSetup.connection(
          [tunnel_id: tid_p1a2, type: :bank_login, meta: meta_a2])
      {conn_p2a1, _} =
        NetworkSetup.connection(
          [tunnel_id: tid_p2a1, type: :bank_login, meta: meta_a1])
      {conn_p2a3, _} =
        NetworkSetup.connection(
          [tunnel_id: tid_p2a3, type: :bank_login, meta: meta_a3])

      # CONTINUE HERE!!

      # Assert player 1 has the two outbound connections created above
      assert [conn_p1a1, conn_p1a2] ==
        TunnelQuery.outbound_connections(player1.server_id)

      # And player 2 has two other outbound connections
      assert [conn_p2a1, conn_p2a3] ==
        TunnelQuery.outbound_connections(player2.server_id)

      # Before logging out of account 1, let's do a wild thing. We'll try to log
      # player 1 out of account *three*, which he isn't even logged in!!!!
      assert [] == BankAction.logout(acc3, player1.server_id)

      # As expected, nothing changed.
      assert [conn_p1a1, conn_p1a2] ==
        TunnelQuery.outbound_connections(player1.server_id)
      assert [conn_p2a1, conn_p2a3] ==
        TunnelQuery.outbound_connections(player2.server_id)

      # Now player 1 will do the actual log out of account 1
      assert [event] = BankAction.logout(acc1, player1.server_id)

      # Aaaand player 1 no longer have the connection with a1, but a2 is there
      assert [conn_p1a2] ==
        TunnelQuery.outbound_connections(player1.server_id)

      # And player 2 connections remain unchanged
      assert [conn_p2a1, conn_p2a3] ==
        TunnelQuery.outbound_connections(player2.server_id)

      # Ensure logout event is the one expected
      assert event == EventSetup.Network.connection_closed(conn_p1a1)
    end
  end

  describe "direct_deposit/2" do
    test "updates the account balance" do
      acc = BankSetup.account!(balance: :random)
      amount = BankHelper.amount()

      assert {:ok, new_acc, [event]} = BankAction.direct_deposit(acc, amount)

      # Updated the balance
      assert new_acc.balance == acc.balance + amount

      # Event is correct
      assert event.account == new_acc
      assert event.reason == :balance

      # And just for the sake of it, change has been persisted on the DB
      assert new_acc == BankQuery.fetch_account(acc.atm_id, acc.account_number)
    end
  end

  defp generate_bank_login_meta(account) do
    %{
      "atm_id" => to_string(account.atm_id),
      "account_number" => account.account_number
    }
  end
end
