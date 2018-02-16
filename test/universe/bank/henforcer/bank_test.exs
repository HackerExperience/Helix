defmodule Helix.Universe.Bank.Henforcer.BankTest do

  use Helix.Test.Case.Integration

  import Helix.Test.Henforcer.Macros

  alias Helix.Universe.Bank.Henforcer.Bank, as: BankHenforcer

  alias Helix.Test.Universe.Bank.Helper, as: BankHelper
  alias Helix.Test.Universe.Bank.Setup, as: BankSetup

  describe "account_exists?/1" do
    test "accepts when account exists" do
      bank_acc = BankSetup.account!()

      assert {true, relay} =
        BankHenforcer.account_exists?(bank_acc.atm_id, bank_acc.account_number)

      assert relay.bank_account == bank_acc

      assert_relay relay, [:bank_account]
    end

    test "rejects when account does not exist" do
      assert {false, reason, _} =
        BankHenforcer.account_exists?(
          BankHelper.atm_id(), BankHelper.account_number()
        )

      assert reason == {:bank_account, :not_found}
    end
  end
end
