defmodule Helix.Universe.Bank.Action.Flow.BankAccountTest do

  use Helix.Test.Case.Integration

  alias HELL.Utils
  alias Helix.Entity.Query.Database, as: DatabaseQuery
  alias Helix.Network.Query.Tunnel, as: TunnelQuery
  alias Helix.Process.Query.Process, as: ProcessQuery
  alias Helix.Universe.Bank.Action.Flow.BankAccount, as: BankAccountFlow

  alias Helix.Test.Universe.Bank.Setup, as: BankSetup
  alias Helix.Test.Entity.Database.Setup, as: DatabaseSetup
  alias Helix.Test.Process.TOPHelper
  alias Helix.Test.Server.Setup, as: ServerSetup

  describe "reveal_password/4" do
    @tag :slow
    test "default life cycle" do
      {token, %{acc: acc}} = BankSetup.token()
      {gateway, %{entity: entity}} = ServerSetup.server()

      # There's an entry of this account on the Database
      DatabaseSetup.entry_bank_account([entity_id: entity.entity_id, acc: acc])
      old_entry = DatabaseQuery.fetch_bank_account(entity, acc)
      refute old_entry.password

      # Create process to reveal password
      {:ok, process} =
        BankAccountFlow.reveal_password(
          token.atm_id,
          token.account_number,
          token.token_id,
          gateway.server_id
        )

      # Ensure process is valid
      assert process.gateway_id == gateway.server_id
      assert process.target_server_id == acc.atm_id
      assert process.process_data.token_id == token.token_id
      assert process.process_data.atm_id == acc.atm_id
      assert process.process_data.account_number == acc.account_number

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

  describe "login_password/5" do
    test "login with valid password on third-party account" do
      time_before_event = Utils.date_before(1)
      {acc, _} = BankSetup.account()
      {server, %{entity: entity}} = ServerSetup.server()

      # Login with the right password
      assert {:ok, connection} =
        BankAccountFlow.login_password(
          acc.atm_id,
          acc.account_number,
          server.server_id,
          [],
          acc.password
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
      :timer.sleep(100)

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
      assert {:ok, connection} =
        BankAccountFlow.login_password(
          acc.atm_id,
          acc.account_number,
          server.server_id,
          [],
          acc.password
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
      :timer.sleep(100)

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
          [],
          "invalid_password"
      )

      # No connections were created
      assert Enum.empty?(TunnelQuery.connections_through_node(server))

      # Wait for events (none should occur, but if they do, we need this timer)
      :timer.sleep(100)

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
      assert {:ok, connection} =
        BankAccountFlow.login_token(
          acc.atm_id,
          acc.account_number,
          server.server_id,
          [],
          token.token_id
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
      :timer.sleep(100)

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
      assert {:ok, connection} =
        BankAccountFlow.login_token(
          acc.atm_id,
          acc.account_number,
          server.server_id,
          [],
          token.token_id
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
      :timer.sleep(100)

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
        [],
        expired_token.token_id
      )

      # No connections were created
      assert Enum.empty?(TunnelQuery.connections_through_node(server))

      # Wait for events (none should occur, but if they do, we need this timer)
      :timer.sleep(100)

      # Ensure nothing was added to the DB
      refute DatabaseQuery.fetch_bank_account(entity, acc)
    end

    test "login with valid token that belongs to another account" do
      {server, %{entity: entity}} = ServerSetup.server()
      {acc, _} = BankSetup.account([owner_id: entity.entity_id])
      {token, _} = BankSetup.token()

      # Login with expired token
      BankAccountFlow.login_token(
        acc.atm_id,
        acc.account_number,
        server.server_id,
        [],
        token.token_id
      )

      # No connections were created
      assert Enum.empty?(TunnelQuery.connections_through_node(server))

      # Wait for events (none should occur, but if they do, we need this timer)
      :timer.sleep(100)

      # Ensure nothing was added to the DB
      refute DatabaseQuery.fetch_bank_account(entity, acc)
    end
  end
end
