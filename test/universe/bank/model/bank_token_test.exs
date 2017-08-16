defmodule Helix.Universe.Bank.Model.BankTokenTest do

  use Helix.Test.IntegrationCase

  alias Ecto.Changeset
  alias Helix.Universe.Bank.Model.BankToken

  @token_ttl 60 * 5

  describe "set_expiration_date" do
    test "it applies the correct TTL" do
      changeset = BankToken.set_expiration_date(%BankToken{})
      assert changeset.valid?
      expiration = Changeset.get_change(changeset, :expiration_date)

      now = DateTime.utc_now()
      assert DateTime.diff(expiration, now) == @token_ttl
    end
  end
end
