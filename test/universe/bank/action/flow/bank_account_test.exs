defmodule Helix.Universe.Bank.Action.Flow.BankAccountTest do

  use Helix.Test.Case.Integration

  alias HELL.Utils
  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Query.Database, as: DatabaseQuery
  alias Helix.Network.Query.Tunnel, as: TunnelQuery
  alias Helix.Process.Query.Process, as: ProcessQuery
  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Universe.Bank.Action.Flow.BankAccount, as: BankAccountFlow
  alias Helix.Universe.Bank.Query.Bank, as: BankQuery

  alias Helix.Test.Account.Setup, as: AccountSetup
  alias Helix.Test.Universe.Bank.Setup, as: BankSetup
  alias Helix.Test.Entity.Database.Setup, as: DatabaseSetup
  alias Helix.Test.Process.TOPHelper
  alias Helix.Test.Server.Setup, as: ServerSetup

  @relay nil

  describe "reveal_password/4" do
    @tag :slow
    test "default life cycle" do
      {token, %{acc: acc}} = BankSetup.token()
      {gateway, %{entity: entity}} = ServerSetup.server()

      # There's an entry of this account on the Database
      DatabaseSetup.entry_bank_account([entity_id: entity.entity_id, acc: acc])
      old_entry = DatabaseQuery.fetch_bank_account(entity, acc)
      refute old_entry.password

      atm = ServerQuery.fetch(acc.atm_id)

      # Create process to reveal password
      {:ok, process} =
        BankAccountFlow.reveal_password(
          acc, token.token_id, gateway, atm, @relay
        )

      # Ensure process is valid
      assert process.gateway_id == gateway.server_id
      assert process.target_id == acc.atm_id
      assert process.data.token_id == token.token_id
      assert process.data.atm_id == acc.atm_id
      assert process.data.account_number == acc.account_number

      TOPHelper.force_completion(process)

      # Process no longer exists
      refute ProcessQuery.fetch(process.process_id)

      # Ensure it updated the Database entry accordingly
      db_entry = DatabaseQuery.fetch_bank_account(entity, acc)
      refute db_entry == old_entry
      assert db_entry.password == acc.password
      refute db_entry.last_update == old_entry.last_update
      refute db_entry.known_balance

      TOPHelper.top_stop(process.gateway_id)
    end
  end

  describe "change_password/4" do
    test "default life cycle" do
      bank_account = BankSetup.account!()
      {gateway, _} = ServerSetup.server()

      atm = ServerQuery.fetch(bank_account.atm_id)
      old_password = bank_account.password

      # Create process to change password
      {:ok, process} =
        BankAccountFlow.change_password(bank_account, gateway, atm, @relay)

      # Ensure process is valid
      assert process.gateway_id == gateway.server_id
      assert process.target_id == bank_account.atm_id

      assert process.src_atm_id == bank_account.atm_id
      assert process.src_acc_number == bank_account.account_number

      TOPHelper.force_completion(process)

      # Process no longer exists
      refute ProcessQuery.fetch(process.process_id)

      # Ensure it changed the `BankAccount`'s password
      atm_id = bank_account.atm_id
      account_number = bank_account.account_number
      bank_account = BankQuery.fetch_account(atm_id, account_number)

      refute bank_account.password == old_password
    end
  end

  describe "login_password/5" do
    test "login with valid password on third-party account" do
      time_before_event = Utils.date_before(1)
      {acc, _} = BankSetup.account()
      {server, %{entity: entity}} = ServerSetup.server()

      # Login with the right password
      assert {:ok, _tunnel, connection} =
        BankAccountFlow.login_password(
          acc.atm_id, acc.account_number, server.server_id, nil, acc.password
        )

      # Ensure connection was created correctly
      assert TunnelQuery.fetch_connection(connection.connection_id)
      assert connection.meta
      assert connection.meta["atm_id"] == acc.atm_id
      assert connection.meta["account_number"] == acc.account_number

      # Ensure correct elements and order on connection
      tunnel = TunnelQuery.fetch(connection.tunnel_id)
      assert [server.server_id, acc.atm_id] == TunnelQuery.get_hops(tunnel)

      # Ensure it updated the Database entry accordingly
      db_entry = DatabaseQuery.fetch_bank_account(entity, acc)
      assert db_entry.password == acc.password
      assert db_entry.known_balance == acc.balance
      assert DateTime.diff(db_entry.last_update, time_before_event) > 0
      assert DateTime.diff(db_entry.last_login_date, time_before_event) > 0
    end

    test "login with valid password on player's own account" do
      {server, %{entity: entity}} = ServerSetup.server()
      {acc, _} = BankSetup.account([owner_id: entity.entity_id])

      # See? The account I'm logging in is mine.
      assert to_string(acc.owner_id) == to_string(entity.entity_id)

      # Login with the right password
      assert {:ok, _tunnel, connection} =
        BankAccountFlow.login_password(
          acc.atm_id, acc.account_number, server.server_id, nil, acc.password
        )

      # Ensure connection was created correctly
      assert TunnelQuery.fetch_connection(connection.connection_id)
      assert connection.meta
      assert connection.meta["atm_id"] == acc.atm_id
      assert connection.meta["account_number"] == acc.account_number

      # Ensure correct elements and order on connection
      tunnel = TunnelQuery.fetch(connection.tunnel_id)
      assert [server.server_id, acc.atm_id] == TunnelQuery.get_hops(tunnel)

      # Wait for events
      # :timer.sleep(100)

      # Nothing was added to the Hacked Database... because it's MY account!
      refute DatabaseQuery.fetch_bank_account(entity, acc)
    end

    test "login with invalid token on third-party" do
      {acc, _} = BankSetup.account()
      {server, %{entity: entity}} = ServerSetup.server()

      # Login with invalid credentials
      BankAccountFlow.login_password(
          acc.atm_id,
          acc.account_number,
          server.server_id,
          nil,
          "invalid_password"
      )

      # No connections were created
      assert Enum.empty?(TunnelQuery.connections_through_node(server))

      # Ensure nothing was added to the DB
      refute DatabaseQuery.fetch_bank_account(entity, acc)
    end
  end

  describe "login_token/5" do
    test "login with valid token on third-party account" do
      time_before_event = Utils.date_before(1)
      {token, %{acc: acc}} = BankSetup.token()
      {server, %{entity: entity}} = ServerSetup.server()

      # Login with the right credentials
      assert {:ok, _tunnel, connection} =
        BankAccountFlow.login_token(
          acc.atm_id, acc.account_number, server.server_id, nil, token.token_id
        )

      # Ensure connection was created correctly
      assert TunnelQuery.fetch_connection(connection.connection_id)
      assert connection.meta
      assert connection.meta["atm_id"] == acc.atm_id
      assert connection.meta["account_number"] == acc.account_number

      # Ensure correct elements and order on connection
      tunnel = TunnelQuery.fetch(connection.tunnel_id)
      assert [server.server_id, acc.atm_id] == TunnelQuery.get_hops(tunnel)

      # # Ensure it updated the Database entry accordingly
      db_entry = DatabaseQuery.fetch_bank_account(entity, acc)
      assert db_entry.token == token.token_id
      refute db_entry.password
      assert db_entry.known_balance == acc.balance
      assert DateTime.diff(db_entry.last_update, time_before_event) > 0
      assert DateTime.diff(db_entry.last_login_date, time_before_event) > 0
    end

    test "login with valid token on player's own account" do
      {server, %{entity: entity}} = ServerSetup.server()
      {acc, _} = BankSetup.account([owner_id: entity.entity_id])
      {token, _} = BankSetup.token([acc: acc])

      # See? The account I'm logging in is mine.
      assert to_string(acc.owner_id) == to_string(entity.entity_id)

      # Login with the right token
      assert {:ok, _tunnel, connection} =
        BankAccountFlow.login_token(
          acc.atm_id, acc.account_number, server.server_id, nil, token.token_id
        )

      # Ensure connection was created correctly
      assert TunnelQuery.fetch_connection(connection.connection_id)
      assert connection.meta
      assert connection.meta["atm_id"] == acc.atm_id
      assert connection.meta["account_number"] == acc.account_number

      # Ensure correct elements and order on connection
      tunnel = TunnelQuery.fetch(connection.tunnel_id)
      assert [server.server_id, acc.atm_id] == TunnelQuery.get_hops(tunnel)

      # Nothing was added to the Hacked Database... because it's MY account!
      refute DatabaseQuery.fetch_bank_account(entity, acc)
    end

    test "login with expired token" do
      {server, %{entity: entity}} = ServerSetup.server()
      {acc, _} = BankSetup.account([owner_id: entity.entity_id])
      {expired_token, _} = BankSetup.token([expired: true, acc: acc])

      # Login with expired token
      BankAccountFlow.login_token(
        acc.atm_id,
        acc.account_number,
        server.server_id,
        nil,
        expired_token.token_id
      )

      # No connections were created
      assert Enum.empty?(TunnelQuery.connections_through_node(server))

      # Ensure nothing was added to the DB
      refute DatabaseQuery.fetch_bank_account(entity, acc)
    end

    test "login with valid token that belongs to another account" do
      {server, %{entity: entity}} = ServerSetup.server()
      {acc, _} = BankSetup.account([owner_id: entity.entity_id])
      {token, _} = BankSetup.token()

      # Login with expired token
      BankAccountFlow.login_token(
        acc.atm_id, acc.account_number, server.server_id, nil, token.token_id
      )

      # No connections were created
      assert Enum.empty?(TunnelQuery.connections_through_node(server))

      # Ensure nothing was added to the DB
      refute DatabaseQuery.fetch_bank_account(entity, acc)
    end
  end

  describe "open/4" do
    test "creates a process to opens account when everything is OK" do
      {account, %{server: gateway}}  = AccountSetup.account(with_server: true)

      account_id = account.account_id

      bank_acc = BankSetup.account!()
      atm_id = bank_acc.atm_id
      atm = ServerQuery.fetch(atm_id)

      assert {:ok, process} =
        BankAccountFlow.open(gateway, account_id, atm, @relay)

      assert process.data.atm_id == atm_id
      assert process.source_entity_id == %Entity.ID{id: account_id.id}

      TOPHelper.force_completion(process)

      refute ProcessQuery.fetch(process.process_id)
    end
  end

  describe "close/4" do
    test "creates a process to close the given bank account" do
      {account, %{server: gateway}}  = AccountSetup.account(with_server: true)
      account_id = account.account_id

      entity_id = %Entity.ID{id: account_id.id}

      bank_acc = BankSetup.account!(owner_id: entity_id)

      atm_id = bank_acc.atm_id
      atm = ServerQuery.fetch(atm_id)
      account_number = bank_acc.account_number

      assert {:ok, process} =
        BankAccountFlow.close(gateway, bank_acc, atm, @relay)

      assert process.data.atm_id == atm_id
      assert process.data.account_number == account_number

      TOPHelper.force_completion(process)

      refute ProcessQuery.fetch(process.process_id)

      refute BankQuery.fetch_account(atm_id, account_number)
    end
  end
end
