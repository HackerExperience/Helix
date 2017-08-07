defmodule Helix.Account.Action.AccountTest do

  use Helix.Test.IntegrationCase

  alias Helix.Cache.Helper, as: CacheHelper
  alias Helix.Account.Action.Account, as: AccountAction
  alias Helix.Account.Model.Account

  alias Helix.Account.Factory

  describe "create/1" do
    test "succeeds with valid input" do
      params = %{
        email: "this_is_actually+0@a_valid_email.com",
        username: "good_username0",
        password: "Would you very kindly let me in, please, good sir"
      }

      assert {:ok, %Account{}} = AccountAction.create(params)

      # HACK: workaround for the flow event
      :timer.sleep(250)
      CacheHelper.sync_test()
    end

    test "returns changeset when input is invalid" do
      params = %{}

      assert {:error, %Ecto.Changeset{}} = AccountAction.create(params)

      params = %{email: "invalid", username: "^invalid", password: "invalid"}
      assert {:error, %Ecto.Changeset{}} = AccountAction.create(params)
    end
  end

  describe "create/3" do
    test "succeeds with valid input" do
      email = "this_is_actually+1@a_valid_email.com"
      username = "good_username1"
      password = "Would you very kindly let me in, please, good sir"

      assert {:ok, %Account{}} = AccountAction.create(email, username, password)

      # HACK: workaround for the flow event
      :timer.sleep(100)
      CacheHelper.sync_test()
    end

    test "returns changeset when input is invalid" do
      result = AccountAction.create("", "", "")
      assert {:error, %Ecto.Changeset{}} = result

      result = AccountAction.create("invalid", "^invalid", "invalid")
      assert {:error, %Ecto.Changeset{}} = result
    end
  end

  describe "login/2" do
    test "succeeds when username and password are correct" do
      password = "foobar 123 password LetMeIn"
      account = Factory.insert(:account, password: password)

      {:ok, acc, _token} = AccountAction.login(account.username, password)

      assert account.account_id == acc.account_id
    end

    test "fails when provided with incorrect password" do
      account = Factory.insert(:account)

      assert {:error, _} = AccountAction.login(account.username, "incorrect pass")
    end

    test "cannot use email as login credential" do
      password = "foobar 123 password LetMeIn"
      account = Factory.insert(:account, password: password)

      assert {:error, _} = AccountAction.login(account.email, password)
    end
  end
end
