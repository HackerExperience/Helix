defmodule Helix.Account.Controller.SessionTest do

  use ExUnit.Case, async: true

  alias Helix.Account.Controller.Session
  alias Helix.Account.Model.AccountSession
  alias Helix.Account.Repo

  alias Helix.Account.Factory

  @moduletag :integration

  describe "generate_token/1" do
    test "succeeds with valid account" do
      account = Factory.insert(:account)

      token = Session.generate_token(account)

      assert is_binary(token)
    end
  end

  describe "validate_token/1" do
    test "succeeds with valid token" do
      account = Factory.insert(:account)

      token = Session.generate_token(account)
      assert {:ok, _, _} = Session.validate_token(token)
    end

    test "fails when session was invalidated" do
      account = Factory.insert(:account)

      token = Session.generate_token(account)
      Session.invalidate_token(token)

      assert {:error, :unauthorized} == Session.validate_token(token)
    end

    test "fails when token is invalid" do
      assert {:error, :unauthorized} == Session.validate_token("foobarbaz")
    end

    test "returns account and session" do
      account = Factory.insert(:account)

      token = Session.generate_token(account)
      {:ok, acc, session} = Session.validate_token(token)

      assert account.account_id == acc.account_id
      assert is_binary(session)
      assert Repo.get(AccountSession, session)
    end
  end

  describe "invalidate_token/1" do
    test "is idempotent" do
      account = Factory.insert(:account)

      token = Session.generate_token(account)

      Session.invalidate_token(token)
      Session.invalidate_token(token)

      assert {:error, :unauthorized} == Session.validate_token(token)
    end
  end

  describe "invalidate_session/1" do
    test "is idempotent" do
      account = Factory.insert(:account)

      token = Session.generate_token(account)
      {:ok, _, session} = Session.validate_token(token)

      Session.invalidate_session(session)
      Session.invalidate_session(session)

      assert {:error, :unauthorized} == Session.validate_token(token)
    end
  end
end
