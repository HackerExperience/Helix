defmodule Helix.Universe.Bank.Event.TokenTest do

  use Helix.Test.Case.Integration

  alias Helix.Event

  alias Helix.Entity.Query.Database, as: DatabaseQuery

  alias Helix.Test.Event.Setup, as: EventSetup
  alias Helix.Test.Entity.Setup, as: EntitySetup
  alias Helix.Test.Universe.Bank.Setup, as: BankSetup

  describe "event reactions" do
    test "accepts when token is created on database after event been fired" do
      # Setups a Bank Account
      bank_acc = BankSetup.account!()

      # Setups a new Entity and gets it's id
      entity_id = EntitySetup.entity!().entity_id

      # Setups a new Token for earlier created Bank Account
      token_id = BankSetup.token!(acc: bank_acc).token_id

      # Setups a BankAccountTokenAcquiredEvent
      event = EventSetup.Bank.token_acquired(token_id, bank_acc, entity_id)

      # Refutes if the Bank Account already exists on Entity's Database
      refute DatabaseQuery.fetch_bank_account(entity_id, bank_acc)

      # Emits BankAccountTokenAcquiredEvent
      Event.emit(event)

      # Fetchs the BankAccount from Entity's Database
      db_bank_acc = DatabaseQuery.fetch_bank_account(entity_id, bank_acc)

      # Asserts that token exists on Entity's Database
      assert db_bank_acc.token == token_id
    end
  end
end
