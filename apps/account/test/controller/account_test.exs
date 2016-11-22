defmodule HELM.Account.Controller.AccountTest do

  use ExUnit.Case, async: true

  alias HELL.TestHelper.Random
  alias HELM.Account.Model.Account
  alias HELM.Account.Repo
  alias HELM.Account.Controller.Account, as: CtrlAccount

  setup do
    account =
      payload()
      |> Account.create_changeset()
      |> Repo.insert!()

    {:ok, account: account}
  end

  # Funnily enough, the very same params can be use to create an account through
  # the controller and the model
  defp payload do
    email = Burette.Internet.email()
    password = Burette.Internet.password()
    %{email: email, password_confirmation: password, password: password}
  end

  describe "account creation" do
    test "succeeds with proper data" do
      assert {:ok, _} = CtrlAccount.create(payload())
    end

    test "fails when email is already in use", %{account: account} do
      payload = %{
        email: account.email,
        password: "toptoptop123",
        password_confirmation: "toptoptop123"}

      assert {:error, changeset} = CtrlAccount.create(payload)
      assert :email in Keyword.keys(changeset.errors)
    end

    test "fails when password confirmation doesn't match" do
      payload = %{payload()| password_confirmation: "toptoper123"}

      assert {:error, changeset} = CtrlAccount.create(payload)
      assert :password_confirmation in Keyword.keys(changeset.errors)
    end

    test "fails when password is too short" do
      payload = %{payload()| password: "123", password_confirmation: "123"}

      assert {:error, changeset} = CtrlAccount.create(payload)
      assert :password in Keyword.keys(changeset.errors)
    end
  end

  describe "find/1" do
    test "succeeds when account exists", %{account: account} do
      assert {:ok, found} = CtrlAccount.find(account.account_id)
      assert account.account_id == found.account_id
    end

    test "fails when account doesn't exists" do
      assert {:error, :notfound} === CtrlAccount.find(Random.pk())
    end
  end

  describe "find_by/1" do
    test "using email", %{account: account} do
      assert {:ok, found} = CtrlAccount.find_by(email: account.email)
      assert account.account_id == found.account_id
    end

    test "failing with invalid email" do
      assert {:error, :notfound} = CtrlAccount.find_by(email: "invalid@email.eita")
    end
  end

  test "delete/1 is idempotent", %{account: account} do
    assert Repo.get_by(Account, account_id: account.account_id)
    CtrlAccount.delete(account.account_id)
    CtrlAccount.delete(account.account_id)
    refute Repo.get_by(Account, account_id: account.account_id)
  end

  describe "update/2" do
    test "update account", %{payload: payload} do
      password = HRand.string(min: 8, max: 16)
      payload2 = %{
        email: HRand.email() |> String.downcase(),
        password: password,
        password_confirmation: password,
        confirmed: true
      }

      assert {:ok, account1} = CtrlAccount.create(payload)
      assert {:ok, account2} = CtrlAccount.update(account1.account_id, payload2)

      assert account2.email == payload2.email
      refute account2.password == account1.password
      assert account2.confirmed == payload2.confirmed
    end

    test "email exists", %{payload: payload} do
      password = HRand.string(min: 8, max: 16)
      payload2 = %{
        email: HRand.email(),
        password: password,
        password_confirmation: password,
        confirmed: true
      }

      assert {:ok, account1} = CtrlAccount.create(payload)
      assert {:ok, _} = CtrlAccount.create(payload2)
      assert {:error, _}    = CtrlAccount.update(account1.account_id, payload2)
    end

    test "account not found" do
      assert {:error, :notfound} = CtrlAccount.update(IPv6.generate([]), %{})
    end
  end

  describe "login/2" do
    test "succeeds with correct email/password", %{account: account} do
      pass = "!!!foobar1234"

      account
      |> Account.update_changeset(%{password: pass, password_confirmation: pass})
      |> Repo.update!()

      assert {:ok, _} = CtrlAccount.login(account.email, pass)
    end

    test "fails when email is invalid" do
      xs = CtrlAccount.login("invalid@email.eita", "password")
      assert {:error, :notfound} === xs
    end

    test "fails when password doesn't match", %{account: account} do
      xs = CtrlAccount.login(account.email, "not_actually_the_correct_password")
      assert {:error, :notfound} === xs
    end
  end
end