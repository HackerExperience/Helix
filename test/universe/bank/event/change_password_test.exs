defmodule Helix.Universe.Bank.Event.ChangePasswordTest do

  use Helix.Test.Case.Integration

  alias Helix.Event

  alias Helix.Universe.Bank.Query.Bank, as: BankQuery

  alias Helix.Test.Event.Setup, as: EventSetup
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Universe.Bank.Setup, as: BankSetup

  describe "event reactions" do
    test "accepts if account's password changes after fired" do
      # Setups a Gateway
      {gateway, %{entity: entity}} = ServerSetup.server()

      # Gets gateway's server_id
      gateway_id = gateway.server_id

      # Setups a BankAccount
      bank_acc = BankSetup.account!(owner_id: entity.entity_id)

      # Stores BankAccount's password for checking later
      old_password = bank_acc.password

      # Setups a ChangePasswordProcessedEvent
      event = EventSetup.Bank.password_change_processed(bank_acc, gateway_id)

      # Emits ChangePasswordProcessedEvent
      Event.emit(event)

      # Fetchs the new BankAccount
      assert bank_acc =
        BankQuery.fetch_account(bank_acc.atm_id, bank_acc.account_number)

      # Refutes if the BankAccount's password still the same as before
      refute bank_acc.password == old_password
    end
  end
end
