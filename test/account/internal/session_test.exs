defmodule Helix.Account.Internal.SessionInternalTest do

  use Helix.Test.IntegrationCase

  alias Helix.Account.Internal.Session, as: SessionInternal
  alias Helix.Account.Model.AccountSession
  alias Helix.Account.Repo

  alias Helix.Account.Factory

  describe "generate_token/1" do
    test "succeeds with valid account" do
      account = Factory.insert(:account)

      token = SessionInternal.generate_token(account)

      assert is_binary(token)
    end
  end

  describe "validate_token/1" do
    test "succeeds with valid token" do
      account = Factory.insert(:account)

      token = SessionInternal.generate_token(account)
      assert {:ok, _, _} = SessionInternal.validate_token(token)
    end

    test "fails when session was invalidated" do
      account = Factory.insert(:account)

      token = SessionInternal.generate_token(account)
      SessionInternal.invalidate_token(token)

      assert {:error, :unauthorized} == SessionInternal.validate_token(token)
    end

    test "fails when token is invalid" do
      assert {:error, :unauthorized} == SessionInternal.validate_token("foobarbaz")
    end

    test "returns account and session" do
      account = Factory.insert(:account)

      token = SessionInternal.generate_token(account)
      {:ok, acc, session} = SessionInternal.validate_token(token)

      assert account.account_id == acc.account_id
      assert is_binary(session)
      assert Repo.get(AccountSession, session)
    end
  end

  describe "invalidate_token/1" do
    test "is idempotent" do
      account = Factory.insert(:account)

      token = SessionInternal.generate_token(account)

      SessionInternal.invalidate_token(token)
      SessionInternal.invalidate_token(token)

      assert {:error, :unauthorized} == SessionInternal.validate_token(token)
    end
  end

  describe "invalidate_session/1" do
    test "is idempotent" do
      account = Factory.insert(:account)

      token = SessionInternal.generate_token(account)
      {:ok, _, session} = SessionInternal.validate_token(token)

      SessionInternal.invalidate_session(session)
      SessionInternal.invalidate_session(session)

      assert {:error, :unauthorized} == SessionInternal.validate_token(token)
    end
  end
end
