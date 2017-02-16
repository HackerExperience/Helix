defmodule Helix.Account.Controller.AccountTest do

  use ExUnit.Case, async: true

  alias HELL.TestHelper.Random
  alias Helix.Account.Controller.Account, as: AccountController
  alias Helix.Account.Model.Account
  alias Helix.Account.Repo

  alias Helix.Account.Factory

  describe "account creation" do
    test "succeeds with proper data" do
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
    test "succeeds when account exists" do
      account = Factory.insert(:account)

      assert {:ok, found} = AccountController.find(account.account_id)
      assert account.account_id == found.account_id
    end

    test "fails when account doesn't exists" do
      assert {:error, :notfound} == AccountController.find(Random.pk())
    end

    test "using email" do
      account = Factory.insert(:account)

      assert {:ok, found} = AccountController.find_by(email: account.email)
      assert account.account_id == found.account_id
    end

    test "failing with invalid email" do
      assert {:error, :notfound} = AccountController.find_by(email: "invalid@email.eita")
    end
  end

  test "account deletion is idempotent" do
    account = Factory.insert(:account)

    assert Repo.get_by(Account, account_id: account.account_id)

    AccountController.delete(account.account_id)
    AccountController.delete(account.account_id)

    refute Repo.get_by(Account, account_id: account.account_id)
  end

  describe "account updating" do
    test "updates its fields" do
      account = Factory.insert(:account)
      p = Factory.params_for(:account)

      params = %{
        email: p.email,
        password: p.password,
        confirmed: true
      }

      assert {:ok, account2} = AccountController.update(account.account_id, params)
      assert params.email == account2.email
      refute account.password == account2.password
      assert params.confirmed == account2.confirmed
    end

    test "email exists" do
      a = Factory.insert(:account)
      params1 = Factory.params_for(:account)
      params2 = %{params1 | email: a.email}

      assert {:ok, account1} = AccountController.create(params1)
      assert {:error, _} = AccountController.update(account1.account_id, params2)
    end

    test "account not found" do
      pk = HELL.TestHelper.Random.pk()

      assert {:error, :notfound} == AccountController.update(pk, %{})
    end
  end

  describe "account login" do
    test "succeeds with correct username/password" do
      account = Factory.insert(:account)
      pass = "!!!foobar1234"

      account
      |> Account.update_changeset(%{password: pass})
      |> Repo.update!()

      assert {:ok, _} = AccountController.login(account.username, pass)
    end

    test "fails when username is invalid" do
      error = AccountController.login("}<]=inv@líd+(usêr)-nämẽ", "password")

      assert {:error, :notfound} == error
    end

    test "fails when password doesn't match" do
      account = Factory.insert(:account)
      error = AccountController.login(account.email, "incorrect_password")

      assert {:error, :notfound} == error
    end
  end
end