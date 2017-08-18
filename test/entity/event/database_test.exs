defmodule Helix.Entity.Event.DatabaseTest do

  use Helix.Test.Case.Integration

  alias Helix.Universe.Bank.Model.BankAccount.PasswordRevealedEvent,
    as: BankAccountPasswordRevealedEvent
  alias Helix.Entity.Event.Database, as: DatabaseHandler
  alias Helix.Entity.Query.Database, as: DatabaseQuery

  alias Helix.Test.Entity.Database.Setup, as: DatabaseSetup

  describe "on cracker conclusion" do
    @tag :pending
    test "adds the server to hacked database"

    @tag :pending
    test "fails if target server changed ip"
  end

  describe "bank_password_revealed/1" do
    test "the entry password is updated" do
      {entry, %{acc: acc}} = DatabaseSetup.entry_bank_account()
      password = "lulz"

      event = %BankAccountPasswordRevealedEvent{
        entity_id: entry.entity_id,
        atm_id: entry.atm_id,
        account_number: entry.account_number,
        password: password
      }

      DatabaseHandler.bank_password_revealed(event)

      on_db = DatabaseQuery.fetch_bank_account(entry.entity_id, acc)

      assert on_db.password == password
      assert on_db.last_update > entry.last_update
      refute on_db.last_login_date
    end

    test "a new entry is created in case it did not exist before" do
      {fake_entry, %{acc: acc}} = DatabaseSetup.fake_entry_bank_account()
      password = "lulz"

      refute DatabaseQuery.fetch_bank_account(fake_entry.entity_id, acc)

      event = %BankAccountPasswordRevealedEvent{
        entity_id: fake_entry.entity_id,
        atm_id: fake_entry.atm_id,
        account_number: fake_entry.account_number,
        password: password
      }

      DatabaseHandler.bank_password_revealed(event)

      on_db = DatabaseQuery.fetch_bank_account(fake_entry.entity_id, acc)

      assert on_db.password == password
      assert on_db.last_update > fake_entry.last_update
      refute on_db.last_login_date
    end
  end
end
