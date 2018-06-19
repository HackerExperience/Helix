defmodule Helix.Universe.Bank.Internal.BankTokenTest do

  use Helix.Test.Case.Integration

  alias Ecto.UUID
  alias Helix.Network.Model.Connection
  alias Helix.Universe.Bank.Internal.BankToken, as: BankTokenInternal

  alias Helix.Test.Universe.Bank.Setup, as: BankSetup
  alias Helix.Network.Model.Connection

  @token_ttl 60 * 5

  describe "fetch/1" do
    test "fetches non-expired token" do
      {token, _} = BankSetup.token()

      token2 = BankTokenInternal.fetch(token.token_id)

      assert token2
      assert token2.token_id == token.token_id
    end

    test "with non-existing token" do
      refute BankTokenInternal.fetch(UUID.generate())
    end
  end

  describe "fetch_by_connection" do
    test "fetches non-expired token" do
      {token, _} = BankSetup.token()

      token2 = BankTokenInternal.fetch_by_connection(token.connection_id)

      assert token2
      assert token2.token_id == token.token_id
    end

    test "with non-existing connection" do
      refute BankTokenInternal.fetch_by_connection(Connection.ID.generate())
    end
  end

  describe "generate/2" do
    test "generates a token" do
      {acc, _} = BankSetup.account()
      connection_id = Connection.ID.generate()

      assert {:ok, token} = BankTokenInternal.generate(acc, connection_id)
      assert String.length(token.token_id) == 36
      assert token.atm_id == acc.atm_id
      assert token.account_number == acc.account_number
      assert token.connection_id == connection_id
    end
  end

  describe "set_expiration/1" do
    test "updates the token expiration" do
      {token, _} = BankSetup.token()

      assert {:ok, token2} = BankTokenInternal.set_expiration(token)

      # Expiration date set
      assert token2.expiration_date

      # And it's set to expire within @token_ttl seconds
      now = DateTime.utc_now()
      assert DateTime.diff(token2.expiration_date, now) == @token_ttl
    end
  end
end
