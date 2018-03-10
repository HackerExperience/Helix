defmodule Helix.Entity.Model.Database.BankAccountTest do

  use Helix.Test.Case.Integration

  alias Ecto.Changeset
  alias Helix.Entity.Model.Database

  alias Helix.Test.Entity.Database.Setup, as: DatabaseSetup

  describe "update_changeset/2" do
    test "password change" do
      {entry, _} = DatabaseSetup.fake_entry_bank_account(real_entity: false)
      password = "woooooow"
      params = %{password: password}

      changeset = Database.BankAccount.update_changeset(entry, params)

      assert changeset.valid?
      assert Changeset.get_change(changeset, :password) == password
    end

    test "token change" do
      {entry, _} = DatabaseSetup.fake_entry_bank_account(real_entity: false)
      token = Ecto.UUID.generate()
      params = %{token: token}

      changeset = Database.BankAccount.update_changeset(entry, params)

      assert changeset.valid?
      assert Changeset.get_change(changeset, :token) == token
    end
  end
end
