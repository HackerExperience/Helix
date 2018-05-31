defmodule Helix.Universe.Bank.Public.IndexTest do

  use Helix.Test.Case.Integration

  alias Helix.Universe.Bank.Public.Index, as: BankIndex

  alias Helix.Test.Universe.Bank.Setup, as: BankSetup

  describe "index/2" do
    test "returns expected data" do
      # Setups a BankAccount.
      bank_account = BankSetup.account!()
      atm_id = bank_account.atm_id
      account_num = bank_account.account_number

      # Gets BankAccount's Index.
      index = BankIndex.index(atm_id, account_num)

      assert index.balance == bank_account.balance
    end
  end

  describe "render_index/1" do
    test "returns JSON-friendly index" do
      # Setups a BankAccount.
      bank_account = BankSetup.account!()
      atm_id = bank_account.atm_id
      account_num = bank_account.account_number

      # Renders BankAccount's Index.
      rendered_index =
        BankIndex.index(atm_id, account_num)
        |> BankIndex.render_index()

      assert rendered_index.balance == bank_account.balance
    end
  end

  describe "render_transfer/1" do
    # Setups a BankTransfer.
    transfer = BankSetup.transfer!()

    # Renders BankTransfer.
    rendered_transfer =
      BankIndex.render_transfer(transfer)

    assert is_binary(rendered_transfer.transfer_id)
    assert is_binary(rendered_transfer.account_from)
    assert is_binary(rendered_transfer.account_to)
    assert is_binary(rendered_transfer.atm_from)
    assert is_binary(rendered_transfer.atm_to)
    assert rendered_transfer.amount == transfer.amount
    assert is_binary(rendered_transfer.started_by)
    assert is_float(rendered_transfer.started_time)
  end
end
