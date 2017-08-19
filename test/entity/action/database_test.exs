defmodule Helix.Entity.Action.DatabaseTest do

  use Helix.Test.Case.Integration

  alias Helix.Entity.Action.Database, as: DatabaseAction
  alias Helix.Entity.Query.Database, as: DatabaseQuery

  alias Helix.Test.Universe.Bank.Setup, as: BankSetup
  alias Helix.Test.Entity.Setup, as: EntitySetup
  alias Helix.Test.Entity.Database.Setup, as: DatabaseSetup

  describe "add_bank_account/2" do
    test "passes the correct data to the Internal interface" do
      {entity, _} = EntitySetup.entity()
      {acc, _} = BankSetup.account([owner_id: entity.entity_id])

      assert {:ok, _} = DatabaseAction.add_bank_account(entity, acc)
    end
  end

  describe "update_bank_password/3" do
    test "password is updated" do
      {entry, %{acc: acc}} = DatabaseSetup.entry_bank_account()
      password = "j3r3m14s"

      assert {:ok, result} =
        DatabaseAction.update_bank_password(entry.entity_id, acc, password)

      # Make sure password has been changed, as well as `last_update`
      assert result.password == password
      assert result.last_update > entry.last_update
    end

    test "new entry is created if there was none" do
      {fake_entry, %{acc: acc}} = DatabaseSetup.fake_entry_bank_account()
      password = "j3r3m14s"

      refute DatabaseQuery.fetch_bank_account(fake_entry.entity_id, acc)

      assert {:ok, _} =
        DatabaseAction.update_bank_password(fake_entry.entity_id, acc, password)

      assert DatabaseQuery.fetch_bank_account(fake_entry.entity_id, acc)
    end

    test "nothing is done if the player owns that account" do
      {entity, _} = EntitySetup.entity()
      {acc, _} = BankSetup.account([owner_id: entity.entity_id])

      assert {:error, reason} =
        DatabaseAction.update_bank_password(entity.entity_id, acc, acc.password)
      assert reason == {:bank_account, :belongs_to_entity}

      refute DatabaseQuery.fetch_bank_account(entity.entity_id, acc)
    end
  end

  describe "update_bank_token/3" do
    test "token is updated" do
      {entry, %{acc: acc}} = DatabaseSetup.entry_bank_account()
      token = Ecto.UUID.generate()

      assert {:ok, result} =
        DatabaseAction.update_bank_token(entry.entity_id, acc, token)

      # Make sure token has been changed, as well as `last_update`
      assert result.token == token
      assert result.last_update > entry.last_update
    end

    test "new entry is created if there was none" do
      {fake_entry, %{acc: acc}} = DatabaseSetup.fake_entry_bank_account()
      token = Ecto.UUID.generate()

      refute DatabaseQuery.fetch_bank_account(fake_entry.entity_id, acc)

      assert {:ok, _} =
        DatabaseAction.update_bank_token(fake_entry.entity_id, acc, token)

      assert DatabaseQuery.fetch_bank_account(fake_entry.entity_id, acc)
    end

    test "nothing is done if the player owns that account" do
      {entity, _} = EntitySetup.entity()
      {acc, _} = BankSetup.account([owner_id: entity.entity_id])
      token = Ecto.UUID.generate()

      assert {:error, reason} =
        DatabaseAction.update_bank_token(entity.entity_id, acc, token)
      assert reason == {:bank_account, :belongs_to_entity}

      refute DatabaseQuery.fetch_bank_account(entity.entity_id, acc)
    end
  end

  describe "update_bank_login/2" do
    test "entry is updated" do
      {entry, %{acc: acc}} = DatabaseSetup.entry_bank_account()

      assert {:ok, result} =
        DatabaseAction.update_bank_login(entry.entity_id, acc)

      assert result.password == acc.password
      assert result.known_balance == acc.balance
      assert result.last_update > entry.last_update
      assert result.last_login_date
    end

    test "new entry is created if there was none" do
      {fake_entry, %{acc: acc}} = DatabaseSetup.fake_entry_bank_account()

      refute DatabaseQuery.fetch_bank_account(fake_entry.entity_id, acc)

      assert {:ok, _} =
        DatabaseAction.update_bank_login(fake_entry.entity_id, acc)

      assert DatabaseQuery.fetch_bank_account(fake_entry.entity_id, acc)
    end

    test "nothing is done if the player owns that account" do
      {entity, _} = EntitySetup.entity()
      {acc, _} = BankSetup.account([owner_id: entity.entity_id])

      assert {:error, reason} =
        DatabaseAction.update_bank_login(entity.entity_id, acc)
      assert reason == {:bank_account, :belongs_to_entity}

      refute DatabaseQuery.fetch_bank_account(entity.entity_id, acc)
    end
  end

  describe "delete_server/3" do
    test "entry is removed" do
      {entry, _} = DatabaseSetup.entry_server()

      # Make sure it is on the DB
      assert DatabaseQuery.fetch_server(
        entry.entity_id,
        entry.network_id,
        entry.server_ip)

      # Delete
      assert :ok ==
        DatabaseAction.delete_server(
          entry.entity_id,
          entry.network_id,
          entry.server_ip)

      # No longer on the DB
      refute DatabaseQuery.fetch_server(
        entry.entity_id,
        entry.network_id,
        entry.server_ip)
    end

    test "non-existent entry isn't removed" do
      {fake_entry, _} = DatabaseSetup.fake_entry_server()
      assert {:error, {:entry, :notfound}} ==
        DatabaseAction.delete_server(
          fake_entry.entity_id,
          fake_entry.network_id,
          fake_entry.server_ip
        )
    end
  end

  describe "delete_bank_account/2" do
    test "entry is removed" do
      {entry, %{acc: acc}} = DatabaseSetup.entry_bank_account()

      # Make sure it is on the DB
      assert DatabaseQuery.fetch_bank_account(entry.entity_id, acc)

      # Delete
      assert :ok == DatabaseAction.delete_bank_account(entry.entity_id, acc)

      # No longer on the DB
      refute DatabaseQuery.fetch_bank_account(entry.entity_id, acc)
    end

    test "non-existent entry isn't removed" do
      {fake, %{acc: acc}} = DatabaseSetup.fake_entry_bank_account()

      assert {:error, {:entry, :notfound}} ==
        DatabaseAction.delete_bank_account(fake.entity_id, acc)
    end
  end
end
