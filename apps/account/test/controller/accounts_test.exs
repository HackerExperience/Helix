defmodule HELM.Account.Controller.AccountsTest do
  use ExUnit.Case

  alias HELL.Random, as: HRand
  alias HELM.Account.Controller.Accounts, as: CtrlAccounts

  setup do
    email = HRand.random_numeric_string()
    pass =
      1..8
      |> Enum.map(fn _ -> HRand.random_numeric_string() end)
      |> Enum.join("")

    payload = %{email: email, password: pass, password_confirmation: pass}

    {:ok, email: email, pass: pass, payload: payload}
  end

  describe "create/1" do
    test "success", %{payload: payload} do
      assert {:ok, _} = CtrlAccounts.create(payload)
    end

    test "account exists", %{payload: payload} do
      {:ok, _} = CtrlAccounts.create(payload)
      {:error, errors} = CtrlAccounts.create(payload)
      error = Keyword.fetch!(errors, :email)
      assert error == {"has already been taken", []}
    end

    test "wrong confirmation", %{email: email, pass: pass} do
      payload = %{email: email, password: pass, password_confirmation: "123"}

      {:error, errors} = CtrlAccounts.create(payload)
      error = Keyword.fetch!(errors, :password_confirmation)
      assert error == {"does not match confirmation", []}
    end

    test "short password", %{email: email} do
      payload = %{email: email, password: "123", password_confirmation: "123"}

      {:error, errors} = CtrlAccounts.create(payload)
      error = Keyword.fetch!(errors, :password)
      assert error == {"should be at least %{count} character(s)", count: 8}
    end
  end

  describe "find/1" do
    test "success", %{payload: payload} do
      {:ok, account} = CtrlAccounts.create(payload)
      {:ok, found} = CtrlAccounts.find(account.account_id)
      assert account.account_id == found.account_id
    end

    test "failure", %{payload: payload} do
      {:ok, _} = CtrlAccounts.create(payload)
      assert {:error, :notfound} = CtrlAccounts.find("")
    end
  end

  describe "find_by/1" do
    test "success with email", %{payload: payload} do
      {:ok, account} = CtrlAccounts.create(payload)
      {:ok, found} = CtrlAccounts.find_by(email: payload.email)
      assert account.account_id == found.account_id
    end

    test "failure with email", %{payload: payload} do
      {:ok, _} = CtrlAccounts.create(payload)
      assert {:error, :notfound} = CtrlAccounts.find_by(email: "")
    end
  end

  test "delete/1 idempotency", %{payload: payload} do
    {:ok, account} = CtrlAccounts.create(payload)
    assert :ok = CtrlAccounts.delete(account.account_id)
    assert :ok = CtrlAccounts.delete(account.account_id)
  end

  describe "login/2" do
    test "success", %{payload: payload, email: email, pass: pass} do
      {:ok, _} = CtrlAccounts.create(payload)
      assert :ok = CtrlAccounts.login(email, pass)
    end

    test "user not found" do
      assert {:error, :notfound} = CtrlAccounts.login(";", "")
    end

    test "wrong password", %{payload: payload, email: email} do
      {:ok, _} = CtrlAccounts.create(payload)
      assert {:error, :notfound} = CtrlAccounts.login(email, "")
    end
  end
end