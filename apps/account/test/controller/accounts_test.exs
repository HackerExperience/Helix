defmodule HELM.Account.Controller.AccountTest do
  use ExUnit.Case

  alias HELL.IPv6
  alias HELL.TestHelper.Random, as: HRand
  alias HELM.Account.Controller.Account, as: CtrlAccount

  setup do
    email = HRand.email()
    pass = HRand.string(min: 8, max: 16)

    payload = %{email: email, password: pass, password_confirmation: pass}

    {:ok, email: email, pass: pass, payload: payload}
  end

  describe "create/1" do
    test "success", %{payload: payload} do
      assert {:ok, _} = CtrlAccount.create(payload)
    end

    test "account exists", %{payload: payload} do
      {:ok, _} = CtrlAccount.create(payload)
      {:error, changeset} = CtrlAccount.create(payload)
      error = Keyword.fetch!(changeset.errors, :email)
      assert error == {"has already been taken", []}
    end

    test "wrong confirmation", %{email: email, pass: pass} do
      payload = %{email: email, password: pass, password_confirmation: "123"}
      {:error, changeset} = CtrlAccount.create(payload)
      error = Keyword.fetch!(changeset.errors, :password_confirmation)
      assert error == {"does not match confirmation", []}
    end

    test "short password", %{email: email} do
      payload = %{email: email, password: "123", password_confirmation: "123"}
      {:error, changeset} = CtrlAccount.create(payload)
      error = Keyword.fetch!(changeset.errors, :password)
      assert error == {"should be at least %{count} character(s)", count: 8}
    end
  end

  describe "find/1" do
    test "success", %{payload: payload} do
      {:ok, account} = CtrlAccount.create(payload)
      {:ok, found} = CtrlAccount.find(account.account_id)
      assert account.account_id == found.account_id
    end

    test "failure", %{payload: payload} do
      {:ok, _} = CtrlAccount.create(payload)
      assert {:error, :notfound} = CtrlAccount.find(IPv6.generate([]))
    end
  end

  describe "find_by/1" do
    test "success with email", %{payload: payload} do
      {:ok, account} = CtrlAccount.create(payload)
      {:ok, found} = CtrlAccount.find_by(email: payload.email)
      assert account.account_id == found.account_id
    end

    test "failure with email", %{payload: payload} do
      {:ok, _} = CtrlAccount.create(payload)
      assert {:error, :notfound} = CtrlAccount.find_by(email: "")
    end
  end

  test "delete/1 idempotency", %{payload: payload} do
    {:ok, account} = CtrlAccount.create(payload)
    assert :ok = CtrlAccount.delete(account.account_id)
    assert :ok = CtrlAccount.delete(account.account_id)
  end

  describe "login/2" do
    test "success", %{payload: payload, email: email, pass: pass} do
      {:ok, _} = CtrlAccount.create(payload)
      assert :ok = CtrlAccount.login(email, pass)
    end

    test "user not found" do
      assert {:error, :notfound} = CtrlAccount.login(";", "")
    end

    test "wrong password", %{payload: payload, email: email} do
      {:ok, _} = CtrlAccount.create(payload)
      assert {:error, :notfound} = CtrlAccount.login(email, "")
    end
  end
end