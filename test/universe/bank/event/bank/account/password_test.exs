defmodule Helix.Universe.Bank.Event.PasswordTest do

  use Helix.Test.Case.Integration

  alias Helix.Event

  alias Helix.Entity.Query.Database, as: DatabaseQuery

  alias Helix.Test.Event.Setup, as: EventSetup
  alias Helix.Test.Entity.Setup, as: EntitySetup
  alias Helix.Test.Universe.Bank.Setup, as: BankSetup

  describe "event reactions" do
    test "accepts if password is added to database when event is fired" do
      # Setups a Bank Account
      bank_acc = BankSetup.account!()

      # Setups a new Entity and gets it's id
      entity_id = EntitySetup.entity!().entity_id

      # Setups a BankAccountPasswordRevealedEvent
      event = EventSetup.Bank.password_revealed(bank_acc, entity_id)

      # Emits BankAccountPasswordRevealedEvent
      Event.emit(event)

      assert password =
        DatabaseQuery.fetch_bank_account(entity_id, bank_acc).password

      assert password == bank_acc.password
    end
  end
end
