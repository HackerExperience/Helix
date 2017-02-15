defmodule Helix.Account.Controller.AccountTest do

  use ExUnit.Case, async: true

  alias HELL.TestHelper.Random
  alias Helix.Account.Controller.Account, as: AccountController
  alias Helix.Account.Model.Account
  alias Helix.Account.Repo

  alias Helix.Account.Factory

  setup_all do
    {:ok, account: create_account()}
  end

  defp create_account() do
    generate_params()
    |> Account.create_changeset()
    |> Repo.insert!()
  end

  # Funnily enough, the very same params can be use to create an account through
  # the controller and the model
  defp generate_params do
    :account
    |> Factory.build()
    |> Map.from_struct()
    |> Map.drop([:display_name, :__meta__])
  end

  describe "account creation" do
    test "succeeds with proper data" do
      params = Factory.params_for(:account)
      assert {:ok, _} = AccountController.create(params)
    end

    test "fails when email is already in use", context do
      account = context.account
      params = Map.put(generate_params(), :email, account.email)

      assert {:error, changeset} = AccountController.create(params)
      assert :email in Keyword.keys(changeset.errors)
    end

    test "fails when username is already in use", context do
      account = context.account
      params = Map.put(generate_params(), :username, account.username)

      assert {:error, changeset} = AccountController.create(params)
      assert :username in Keyword.keys(changeset.errors)
    end

    test "fails when password is too short" do
      params = %{generate_params()| password: "123"}

      assert {:error, changeset} = AccountController.create(params)
      assert :password in Keyword.keys(changeset.errors)
    end
  end

  describe "account fetching" do
    test "succeeds when account exists", context do
      account = context.account
      assert {:ok, found} = AccountController.find(account.account_id)
      assert account.account_id == found.account_id
    end

    test "fails when account doesn't exists" do
      assert {:error, :notfound} == AccountController.find(Random.pk())
    end

    test "using email", context do
      account = context.account
      assert {:ok, found} = AccountController.find_by(email: account.email)
      assert account.account_id == found.account_id
    end

    test "failing with invalid email" do
      assert {:error, :notfound} = AccountController.find_by(email: "invalid@email.eita")
    end
  end

  test "account deletion is idempotent" do
    account = create_account()

    assert Repo.get_by(Account, account_id: account.account_id)
    AccountController.delete(account.account_id)
    AccountController.delete(account.account_id)
    refute Repo.get_by(Account, account_id: account.account_id)
  end

  describe "account updating" do
    test "updates its fields" do
      account = create_account()
      params =
        generate_params()
        |> Map.drop([:username])
        |> Map.put(:confirmed, true)

      assert {:ok, account2} = AccountController.update(account.account_id, params)

      assert params.email == account2.email
      refute account.password == account2.password
      assert params.confirmed == account2.confirmed
    end

    test "email exists" do
      account = create_account()
      params = generate_params()
      params2 = Map.put(params, :email, account.email)

      assert {:ok, account2} = AccountController.create(params)
      assert {:error, _} = AccountController.update(account2.account_id, params2)
    end

    test "account not found" do
      pk = HELL.TestHelper.Random.pk()
      assert {:error, :notfound} == AccountController.update(pk, %{})
    end
  end

  describe "account login" do
    test "succeeds with correct username/password" do
      account = create_account()
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

    test "fails when password doesn't match", context do
      account = context.account
      error = AccountController.login(account.email, "incorrect_password")
      assert {:error, :notfound} == error
    end
  end
end