defmodule Helix.Account.Controller.SessionTest do

  use ExUnit.Case, async: true

  alias HELL.TestHelper.Random
  alias Helix.Account.Controller.Session, as: SessionController
  alias Helix.Account.Model.Account

  alias Helix.Account.Factory

  @moduletag :unit

  describe "token generation" do
    test "succeeds with valid account" do
      params = Factory.build(:account)
      account = Map.merge(params, %{account_id: Random.pk()})

      {:ok, token, claims} = SessionController.create(account)

      assert is_binary(token)
      assert account.account_id == claims["sub"]
    end

    test "fails with invalid data" do
      assert {:error, _} = SessionController.create(%{})
      assert {:error, _} = SessionController.create(%Account{})
    end

  end

  describe "token validation" do
    test "validates newly generated token" do
      account = %Account{account_id: Random.pk()}

      {:ok, token, claims} = SessionController.create(account)
      assert {:ok, verified_claims} = SessionController.validate(token)

      assert verified_claims == claims
    end

    test "does not validate expired token" do
      account = %Account{account_id: Random.pk()}
      claims = %{"exp": 12345}

      {:ok, token, _} = Guardian.encode_and_sign(account, :access, claims)
      assert {:error, :token_expired} = Guardian.decode_and_verify(token)
    end
  end
end
