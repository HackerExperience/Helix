defmodule Helix.Universe.Bank.Model.BankTransferTest do

  use ExUnit.Case, async: true

  alias Helix.Universe.Bank.Model.BankTransfer

  alias Helix.Test.Account.Helper, as: AccountHelper
  alias Helix.Test.Server.Helper, as: ServerHelper

  defp valid_params do
    %{
      account_from: 1234,
      account_to: 4321,
      atm_from: ServerHelper.id(),
      atm_to: ServerHelper.id(),
      amount: 500,
      started_by: AccountHelper.id()
    }
  end

  describe "create_changeset/1" do
    test "with valid data" do
      changeset = BankTransfer.create_changeset(valid_params())
      transfer = Ecto.Changeset.apply_changes(changeset)

      assert changeset.valid?
      assert transfer.started_time
    end

    test "with invalid transfer amount" do
      changeset = BankTransfer.create_changeset(%{valid_params() | amount: 0})
      refute changeset.valid?
    end

    test "with identical accounts" do
      params = valid_params()
      bogus_params = %{params | account_from: 1000, account_to: 1000}

      changeset = BankTransfer.create_changeset(bogus_params)
      refute changeset.valid?
    end

    test "adds start time correctly" do
      params = valid_params()
      changeset = BankTransfer.create_changeset(params)
      transfer = Ecto.Changeset.apply_changes(changeset)

      assert changeset.valid?
      assert transfer.started_time
    end
  end
end
