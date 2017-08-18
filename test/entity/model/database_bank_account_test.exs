defmodule Helix.Entity.Model.DatabaseBankAccountTest do

  use ExUnit.Case, async: true

  alias Ecto.Changeset
  alias Helix.Entity.Model.DatabaseBankAccount

  alias Helix.Test.Entity.Database.Setup, as: DatabaseSetup

  describe "update_changeset/2" do
    test "password change" do
      {entry, _} = DatabaseSetup.fake_entry_bank_account()
      password = "woooooow"
      params = %{password: password}

      changeset = DatabaseBankAccount.update_changeset(entry, params)

      assert changeset.valid?
      assert Changeset.get_change(changeset, :password) == password
    end
  end

end
