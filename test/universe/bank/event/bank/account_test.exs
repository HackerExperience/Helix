defmodule Helix.Universe.Bank.Event.AccountTest do

  use Helix.Test.Case.Integration

  alias Helix.Event

  alias Helix.Entity.Query.Database, as: DatabaseQuery

  alias Helix.Test.Event.Setup, as: EventSetup
  alias Helix.Test.Entity.Setup, as: EntitySetup
  alias Helix.Test.Universe.Bank.Setup, as: BankSetup

  describe "event reactions" do
    test "login reactions for logging from non-owner entity" do
      # Setups a Bank Account
      bank_acc = BankSetup.account!()

      # Setups a new Entity and gets it's id
      entity_id = EntitySetup.entity!().entity_id

      # Setups a BankAccountLoginEvent for earlier created Bank Account
      event = EventSetup.Bank.login(bank_acc, entity_id)

      # Emit login event
      Event.emit(event)

      # Asserts that the Bank Account has been created on created entity's
      # database and that Bank Account's information are the same
      assert db_acc = DatabaseQuery.fetch_bank_account(entity_id, bank_acc)
      assert bank_acc.account_number == db_acc.account_number
      assert bank_acc.atm_id == db_acc.atm_id
      assert bank_acc.password == db_acc.password
      assert bank_acc.balance == db_acc.known_balance
    end
  end
end
