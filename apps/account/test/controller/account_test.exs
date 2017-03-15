defmodule Helix.Account.Controller.AccountTest do

  use ExUnit.Case, async: true

  alias Comeonin.Bcrypt
  alias HELL.TestHelper.Random
  alias Helix.Account.Controller.Account, as: AccountController
  alias Helix.Account.Model.Account
  alias Helix.Account.Repo

  alias Helix.Account.Factory

  describe "account creation" do
    test "succeeds with valid params" do
      params = Factory.params_for(:account)

      assert {:ok, _} = AccountController.create(params)
    end

    test "fails when email is already in use" do
      account = Factory.insert(:account)
      params = %{Factory.params_for(:account) | email: account.email}

      assert {:error, changeset} = AccountController.create(params)
      assert :email in Keyword.keys(changeset.errors)
    end

    test "fails when username is already in use" do
      account = Factory.insert(:account)
      params = %{Factory.params_for(:account) | username: account.username}

      assert {:error, changeset} = AccountController.create(params)
      assert :username in Keyword.keys(changeset.errors)
    end

    test "fails when password is too short" do
      params = %{Factory.params_for(:account) | password: "123"}

      assert {:error, changeset} = AccountController.create(params)
      assert :password in Keyword.keys(changeset.errors)
    end
  end

  describe "account fetching" do
    test "succeeds by id" do
      account = Factory.insert(:account)

      assert {:ok, found} = AccountController.find(account.account_id)
      assert account.account_id == found.account_id
    end

    test "succeeds by email" do
      account = Factory.insert(:account)

      assert [found] = AccountController.find_by(email: account.email)
      assert account.account_id == found.account_id
    end

    test "succeeds by username" do
      account = Factory.insert(:account)

      assert [found] = AccountController.find_by(username: account.username)
      assert account.account_id == found.account_id
    end

    test "returns empty list when email isn't in use" do
      assert [] == AccountController.find_by(email: "a@bc.com")
    end

    test "returns empty list when username isn't in use" do
      assert [] == AccountController.find_by(username: "abcdef")
    end

    test "fails when account doesn't exist" do
      assert {:error, :notfound} == AccountController.find(Random.pk())
    end
  end

  describe "account deleting" do
    test "succeeds by struct and id" do
      account1 = Factory.insert(:account)
      account2 = Factory.insert(:account)

      AccountController.delete(account1)
      AccountController.delete(account2.account_id)

      refute Repo.get_by(Account, account_id: account1.account_id)
      refute Repo.get_by(Account, account_id: account2.account_id)
    end

    test "is idempotent" do
      account = Factory.insert(:account)

      assert Repo.get_by(Account, account_id: account.account_id)

      AccountController.delete(account.account_id)
      AccountController.delete(account.account_id)

      refute Repo.get_by(Account, account_id: account.account_id)
    end
  end

  describe "account updating" do
    test "changes its fields" do
      account = Factory.insert(:account)
      params = Factory.params_for(:account)
      update_params = %{
        email: params.email,
        password: params.password,
        confirmed: true
      }

      {:ok, updated_account} = AccountController.update(account, update_params)

      assert update_params.email == updated_account.email
      assert Bcrypt.checkpw(update_params.password, updated_account.password)
      assert update_params.confirmed == updated_account.confirmed
    end

    test "fails when email is already in use" do
      account1 = Factory.insert(:account)
      account2 = Factory.insert(:account)

      params = %{email: account1.email}

      {:error, cs} = AccountController.update(account2, params)

      assert :email in Keyword.keys(cs.errors)
    end
  end

  describe "account signing in" do
    test "succeeds with correct username and password" do
      params = Factory.params_for(:account)
      pass = params.password

      {:ok, account} = AccountController.create(params)

      assert {:ok, _} = AccountController.login(account.username, pass)
    end

    test "fails when username is invalid" do
      error = AccountController.login("invalid_username", "any_password")

      assert {:error, :notfound} == error
    end

    test "fails when password doesn't match" do
      params = Factory.params_for(:account)
      {:ok, account} = AccountController.create(params)
      error = AccountController.login(account.username, "incorrect_password")

      assert {:error, :notfound} == error
    end
  end
end