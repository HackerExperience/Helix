defmodule Helix.Universe.Bank.Model.BankTransferTest do

  use Helix.Test.IntegrationCase

  alias HELL.TestHelper.Random
  alias Helix.Universe.Bank.Model.BankTransfer

  defp valid_params do
    %{
      account_from: 1234,
      account_to: 4321,
      atm_from: Random.pk(),
      atm_to: Random.pk(),
      amount: 500,
      started_by: Random.pk()
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
