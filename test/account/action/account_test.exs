defmodule Helix.Account.Action.AccountTest do

  use Helix.Test.Case.Integration

  alias Helix.Test.Cache.Helper, as: CacheHelper
  alias Helix.Account.Action.Account, as: AccountAction
  alias Helix.Account.Model.Account

  alias Helix.Test.Account.Factory

  describe "create/3" do
    test "succeeds with valid input" do
      email = "this_is_actually+1@a_valid_email.com"
      username = "good_username1"
      password = "Would you very kindly let me in, please, good sir"

      assert {:ok, account, [event, _]} =
        AccountAction.create(email, username, password)

      assert %Account{} = account
      assert event.account == account

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
