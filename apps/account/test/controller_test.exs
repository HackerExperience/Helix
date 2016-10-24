defmodule HELM.Account.ControllerTest do
  use ExUnit.Case

  alias HELL.Random, as: HRand
  alias HELM.Account.Controller, as: AccountCtrl

  setup do
    email = HRand.random_numeric_string()
    pass =
      1..8
      |> Enum.map(fn _ -> HRand.random_numeric_string() end)
      |> Enum.reduce(&(&1 <> &2))

    {:ok, email: email, pass: pass}
  end

  describe "create/3" do
    test "success", data do
      assert {:ok, account} =
        AccountCtrl.create(data.email, data.pass, data.pass)
    end

    test "account exists", data do
      {:ok, account} = AccountCtrl.create(data.email, data.pass, data.pass)
      assert {:error, :email_taken} =
        AccountCtrl.create(data.email, data.pass, data.pass)
    end

    test "wrong confirmation", data do
      assert {:error, :wrong_password_confirmation} =
        AccountCtrl.create(data.email, data.pass, "123")
    end

    test "short password", data do
      assert {:error, :password_too_short} =
        AccountCtrl.create(data.email, "", "")
    end
  end

  describe "find/1" do
    test "success", data do
      {:ok, account} = AccountCtrl.create(data.email, data.pass, data.pass)
      assert {:ok, account} = AccountCtrl.find(account.account_id)
    end

    test "failure", data do
      {:ok, account} = AccountCtrl.create(data.email, data.pass, data.pass)
      assert {:error, :notfound} = AccountCtrl.find("")
    end
  end

  describe "find_by/1" do
    test "success with email", data do
      {:ok, account} = AccountCtrl.create(data.email, data.pass, data.pass)
      assert {:ok, acount} = AccountCtrl.find_by email: data.email
    end

    test "failure with email", data do
      {:ok, account} = AccountCtrl.create(data.email, data.pass, data.pass)
      assert {:error, :notfound} = AccountCtrl.find_by email: ""
    end
  end

  describe "delete/1" do
    test "success", data do
      {:ok, account} = AccountCtrl.create(data.email, data.pass, data.pass)
      assert {:ok, _} =
        AccountCtrl.delete(account.account_id)
    end

    test "failure", data do
      {:ok, account} = AccountCtrl.create(data.email, data.pass, data.pass)
      {:ok, _} = AccountCtrl.delete(account.account_id)
      assert {:error, :notfound} =
        AccountCtrl.delete(account.account_id)
    end
  end
end
