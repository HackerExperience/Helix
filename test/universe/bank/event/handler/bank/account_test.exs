defmodule Helix.Universe.Bank.Event.Handler.Bank.AccountTest do

  use Helix.Test.Case.Integration

  alias Helix.Universe.Bank.Query.Bank, as: BankQuery

  alias Helix.Test.Event.Helper, as: EventHelper
  alias Helix.Test.Event.Setup, as: EventSetup
  alias Helix.Test.Universe.Bank.Setup, as: BankSetup

  describe "virus_collected/1" do
    test "updates the account balance" do
      bank_acc = BankSetup.account!(balance: :random)

      event = EventSetup.Software.Virus.collected(bank_account: bank_acc)

      # Emit the event
      EventHelper.emit(event)

      new_bank_acc =
        BankQuery.fetch_account(bank_acc.atm_id, bank_acc.account_number)

      # Balance was updated
      assert new_bank_acc.balance == bank_acc.balance + event.earnings
    end
  end
end
