defmodule Helix.Universe.Bank.Event.RevealPasswordTest do

  use Helix.Test.Case.Integration

  alias Helix.Event

  alias Helix.Entity.Query.Database, as: DatabaseQuery

  alias Helix.Test.Event.Setup, as: EventSetup
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Universe.Bank.Setup, as: BankSetup

  describe "event reactions" do
    test "accepts if account's password is revealed" do
      # Setups a Gateway
      {gateway, %{entity: entity}} = ServerSetup.server()

      # Gets gateway's server_id
      gateway_id = gateway.server_id

      # Setups a BankAccount
      bank_acc = BankSetup.account!()

      # Setups a BankAccount Token
      token_id = BankSetup.token!(acc: bank_acc).token_id

      # Setups a RevealPasswordProcessedEvent
      event =
        EventSetup.Bank.password_reveal_processed(
          bank_acc,
          gateway_id,
          token_id
          )

      # Refutes that earlier created bank account exists.
      refute DatabaseQuery.fetch_bank_account(entity, bank_acc)

      # Emits RevealPasswordProcessedEvent
      Event.emit(event)

      # Asserts that account exists on Entity's database
      assert db_bank_acc = DatabaseQuery.fetch_bank_account(entity, bank_acc)

      # Asserts that password is revealed on Entity's database
      assert db_bank_acc.password == bank_acc.password
    end
  end
end
