defmodule Helix.Account.Internal.SessionInternalTest do

  use Helix.Test.Case.Integration

  alias Helix.Account.Internal.Session, as: SessionInternal
  alias Helix.Account.Model.AccountSession
  alias Helix.Account.Repo

  alias Helix.Test.Account.Setup, as: AccountSetup

  describe "generate_token/1" do
    test "succeeds with valid account" do
      account = AccountSetup.account!()

      {:ok, token} = SessionInternal.generate_token(account)

      assert is_binary(token)
    end
  end

  describe "validate_token/1" do
    test "succeeds with valid token" do
      account = AccountSetup.account!()

      {:ok, token} = SessionInternal.generate_token(account)
      assert {:ok, _, _} = SessionInternal.validate_token(token)
    end

    test "fails when session was invalidated" do
      account = AccountSetup.account!()

      {:ok, token} = SessionInternal.generate_token(account)
      {:ok, _, session} = SessionInternal.validate_token(token)
      SessionInternal.invalidate_session(session)

      assert {:error, :unauthorized} == SessionInternal.validate_token(token)
    end

    test "fails when token is invalid" do
      assert {:error, :unauthorized} == SessionInternal.validate_token("foobar")
    end

    test "returns account and session" do
      account = AccountSetup.account!()

      {:ok, token} = SessionInternal.generate_token(account)
      {:ok, acc, session} = SessionInternal.validate_token(token)

      assert account.account_id == acc.account_id
      assert Repo.get(AccountSession, session)
    end
  end

  describe "invalidate_session/1" do
    test "removes session entry" do
      account = AccountSetup.account!()

      {:ok, token} = SessionInternal.generate_token(account)
      {:ok, _, session} = SessionInternal.validate_token(token)

      SessionInternal.invalidate_session(session)

      assert {:error, :unauthorized} == SessionInternal.validate_token(token)
      refute Repo.get(AccountSession, session)
    end
  end
end
