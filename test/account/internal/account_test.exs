defmodule Helix.Account.Internal.AccountTest do

  use Helix.Test.Case.Integration

  alias Comeonin.Bcrypt
  alias Helix.Account.Internal.Account, as: AccountInternal
  alias Helix.Account.Model.Account
  alias Helix.Account.Model.AccountSetting
  alias Helix.Account.Repo

  alias HELL.TestHelper.Random
  alias Helix.Test.Cache.Helper, as: CacheHelper
  alias Helix.Test.Account.Helper, as: AccountHelper
  alias Helix.Test.Account.Setup, as: AccountSetup

  defp params do
    %{
      username: Random.username(),
      email: Burette.Internet.email(),
      password: Burette.Internet.password()
    }
  end

  describe "creation" do
    test "succeeds with valid params" do
      params = %{
        username: Random.username(),
        email: Random.email(),
        password: Random.password()
      }

      assert {:ok, _} = AccountInternal.create(params)

      CacheHelper.sync_test()
    end

    test "fails when email is already in use" do
      {account, _} = AccountSetup.account()
      params = %{params()| email: account.email}

      assert {:error, changeset} = AccountInternal.create(params)
      assert :email in Keyword.keys(changeset.errors)
    end

    test "fails when username is already in use" do
      {account, _} = AccountSetup.account()
      params = %{params()| username: account.username}

      assert {:error, changeset} = AccountInternal.create(params)
      assert :username in Keyword.keys(changeset.errors)
    end

    test "fails when password is too short" do
      params = %{params()| password: "123"}

      assert {:error, changeset} = AccountInternal.create(params)
      assert :password in Keyword.keys(changeset.errors)
    end
  end

  describe "fetching" do
    test "succeeds by id" do
      {account, _} = AccountSetup.account()
      assert %Account{} = AccountInternal.fetch(account.account_id)
    end

    test "succeeds by email" do
      {account, _} = AccountSetup.account()
      assert %Account{} = AccountInternal.fetch_by_email(account.email)
    end

    test "succeeds by username" do
      {account, _} = AccountSetup.account()
      assert %Account{} = AccountInternal.fetch_by_username(account.username)
    end

    test "fails when account with id doesn't exist" do
      refute AccountInternal.fetch(AccountHelper.id())
    end

    test "fails when account with email doesn't exist" do
      refute AccountInternal.fetch_by_email(Random.email())
    end

    test "fails when account with username doesn't exist" do
      refute AccountInternal.fetch_by_username(Random.username())
    end
  end

  describe "delete/1" do
    test "removes entry" do
      account = AccountSetup.account!()

      assert AccountInternal.fetch(account.account_id)

      AccountInternal.delete(account)

      refute AccountInternal.fetch(account.account_id)
    end
  end

  describe "account updating" do
    test "changes its fields" do
      account = AccountSetup.account!()
      params = %{
        email: Random.email(),
        password: Random.password(),
        confirmed: true
      }

      {:ok, updated_account} = AccountInternal.update(account, params)

      assert params.email == updated_account.email
      assert Bcrypt.checkpw(params.password, updated_account.password)
      assert params.confirmed == updated_account.confirmed
    end

    test "fails when email is already in use" do
      account1 = AccountSetup.account!()
      account2 = AccountSetup.account!()

      params = %{email: account1.email}

      {:error, cs} = AccountInternal.update(account2, params)

      assert :email in Keyword.keys(cs.errors)
    end
  end

  describe "putting settings" do
    test "succeeds with valid params" do
      account = AccountSetup.account!()
      settings = %{is_beta: true}

      AccountInternal.put_settings(account, settings)
      %{settings: got} = Repo.get(AccountSetting, account.account_id)

      assert settings == Map.from_struct(got)
    end

    test "fails with contract violating params" do
      account = AccountSetup.account!()
      bogus = %{is_beta: "uhe"}
      result = AccountInternal.put_settings(account, bogus)

      assert {:error, _} = result
    end
  end

  describe "getting settings" do
    @tag :pending
    test "includes modified settings" do
      # defaults =
      #   %Setting{}
      #   |> Map.from_struct()
      #   |> MapSet.new()

      # custom_keys = fn settings ->
      #   settings
      #   |> Map.from_struct()
      #   |> Enum.reject(&MapSet.member?(defaults, &1))
      #   |> Keyword.keys()
      # end

      # %{account: account, settings: settings} =
      #   Factory.insert(:account_setting)

      # result =
      #   account
      #   |> AccountInternal.get_settings()
      #   |> custom_keys.()

      # assert custom_keys.(settings) == result
    end
  end
end
