defmodule Helix.Entity.Action.DatabaseTest do

  use Helix.Test.IntegrationCase

  alias Helix.Entity.Action.Database, as: DatabaseAction
  alias Helix.Entity.Query.Database, as: DatabaseQuery

  alias Helix.Test.Universe.Bank.Setup, as: BankSetup
  alias Helix.Test.Entity.Setup, as: EntitySetup
  alias Helix.Test.Entity.Database.Setup, as: DatabaseSetup

  describe "add_bank_account/2" do
    test "passes the correct data to the Internal interface" do
      entity = EntitySetup.entity()
      acc = BankSetup.bank_account([owner_id: entity.entity_id])

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
  end

  describe "delete_server/3" do
    test "entry is removed" do
      entry = DatabaseSetup.entry_server()

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
      fake_entry = DatabaseSetup.fake_entry_server()
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
