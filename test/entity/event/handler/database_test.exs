defmodule Helix.Entity.Event.Handler.DatabaseTest do

  use Helix.Test.Case.Integration

  alias Helix.Entity.Event.Handler.Database, as: DatabaseHandler
  alias Helix.Entity.Query.Database, as: DatabaseQuery

  alias Helix.Test.Event.Setup, as: EventSetup
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

      event =
        EventSetup.Bank.password_revealed(
          acc,
          entry.entity_id,
          [password: password])

      DatabaseHandler.bank_password_revealed(event)

      on_db = DatabaseQuery.fetch_bank_account(entry.entity_id, acc)

      assert on_db.password == password
      refute on_db.token
      refute on_db.last_login_date

      diff = DateTime.diff(on_db.last_update, entry.last_update, :millisecond)
      assert diff > 0
    end

    test "a new entry is created in case it did not exist before" do
      {fake_entry, %{acc: acc}} = DatabaseSetup.fake_entry_bank_account()
      password = "lulz"

      refute DatabaseQuery.fetch_bank_account(fake_entry.entity_id, acc)

      event =
        EventSetup.Bank.password_revealed(
          acc,
          fake_entry.entity_id,
          [password: password])

      DatabaseHandler.bank_password_revealed(event)

      on_db = DatabaseQuery.fetch_bank_account(fake_entry.entity_id, acc)

      assert on_db.password == password
      refute on_db.last_login_date

      diff =
        DateTime.diff(on_db.last_update, fake_entry.last_update, :millisecond)
      assert diff > 0
    end
  end

  describe "bank_token_acquired/1" do
    test "the entry token is updated" do
      {entry, %{acc: acc}} = DatabaseSetup.entry_bank_account()
      token = Ecto.UUID.generate()

      event = EventSetup.Bank.token_acquired(token, acc, entry.entity_id)

      DatabaseHandler.bank_token_acquired(event)

      on_db = DatabaseQuery.fetch_bank_account(entry.entity_id, acc)

      assert on_db.token == token
      refute on_db.password
      refute on_db.last_login_date

      diff = DateTime.diff(on_db.last_update, entry.last_update, :millisecond)
      assert diff > 0
    end

    test "a new entry is created in case it did not exist before" do
      {fake_entry, %{acc: acc}} = DatabaseSetup.fake_entry_bank_account()
      token = Ecto.UUID.generate()

      refute DatabaseQuery.fetch_bank_account(fake_entry.entity_id, acc)

      event = EventSetup.Bank.token_acquired(token, acc, fake_entry.entity_id)

      DatabaseHandler.bank_token_acquired(event)

      on_db = DatabaseQuery.fetch_bank_account(fake_entry.entity_id, acc)

      assert on_db.token == token
      refute on_db.password
      refute on_db.last_login_date

      diff =
        DateTime.diff(on_db.last_update, fake_entry.last_update, :millisecond)
      assert diff > 0
    end
  end

  describe "bank_account_login" do
    test "the entry is updated" do
      {entry, %{acc: acc}} = DatabaseSetup.entry_bank_account()

      event = EventSetup.Bank.login(acc, entry.entity_id)

      DatabaseHandler.bank_account_login(event)

      on_db = DatabaseQuery.fetch_bank_account(entry.entity_id, acc)

      refute on_db.token
      assert on_db.password == acc.password
      assert on_db.last_login_date
      assert on_db.known_balance == acc.balance

      diff = DateTime.diff(on_db.last_update, entry.last_update, :millisecond)
      assert diff > 0
    end

    test "a new entry is created in case it did not exist before" do
      {fake_entry, %{acc: acc}} = DatabaseSetup.fake_entry_bank_account()

      refute DatabaseQuery.fetch_bank_account(fake_entry.entity_id, acc)

      event = EventSetup.Bank.login(acc, fake_entry.entity_id)

      DatabaseHandler.bank_account_login(event)

      on_db = DatabaseQuery.fetch_bank_account(fake_entry.entity_id, acc)

      refute on_db.token
      assert on_db.password == acc.password
      assert on_db.last_login_date
      assert on_db.known_balance == acc.balance

      diff =
        DateTime.diff(on_db.last_update, fake_entry.last_update, :millisecond)
      assert diff > 0
    end
  end
end
