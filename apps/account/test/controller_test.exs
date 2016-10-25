defmodule HELM.Account.ControllerTest do
  use ExUnit.Case

  alias HELL.Random, as: HRand
  alias HELM.Account.Controller, as: AccountCtrl

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
      assert {:ok, account} = AccountCtrl.create(payload)
    end

    test "account exists", %{payload: payload} do
      {:ok, account} = AccountCtrl.create(payload)
      error = %{password_confirmation: ["does not match confirmation"]}
      assert {:error, error} = AccountCtrl.create(payload)
    end

    test "wrong confirmation", %{email: email, pass: pass} do
      payload = %{email: email, password: pass, password_confirmation: "123"}
      error = %{email: ["has already been taken"]}
      assert {:error, error} = AccountCtrl.create(payload)
    end

    test "short password", %{email: email} do
      payload = %{email: email, password: "123", password_confirmation: "123"}
      error = %{password: ["should be at least 8 character(s)"]}
      assert {:error, error} = AccountCtrl.create(payload)
    end
  end

  describe "find/1" do
    test "success", %{payload: payload} do
      {:ok, account} = AccountCtrl.create(payload)
      assert {:ok, account} = AccountCtrl.find(account.account_id)
    end

    test "failure", %{payload: payload} do
      {:ok, account} = AccountCtrl.create(payload)
      assert {:error, :notfound} = AccountCtrl.find("")
    end
  end

  describe "find_by/1" do
    test "success with email", %{payload: payload} do
      {:ok, account} = AccountCtrl.create(payload)
      assert {:ok, acount} = AccountCtrl.find_by email: payload.email
    end

    test "failure with email", %{payload: payload} do
      {:ok, account} = AccountCtrl.create(payload)
      assert {:error, :notfound} = AccountCtrl.find_by email: ""
    end
  end

  test "delete/1 idempotency", %{payload: payload} do
    {:ok, account} = AccountCtrl.create(payload)
    assert :ok = AccountCtrl.delete(account.account_id)
    assert :ok = AccountCtrl.delete(account.account_id)
  end

  describe "login/2" do
    test "success", %{payload: payload, email: email, pass: pass} do
      {:ok, account} = AccountCtrl.create(payload)
      assert :ok = AccountCtrl.login(email, pass)
    end

    test "user not found", %{payload: payload, email: email, pass: pass} do
      assert {:error, :notfound} = AccountCtrl.login(";", "")
    end

    test "wrong password", %{payload: payload, email: email, pass: pass} do
      {:ok, account} = AccountCtrl.create(payload)
      assert {:error, :notfound} = AccountCtrl.login(email, "")
    end
  end
end
