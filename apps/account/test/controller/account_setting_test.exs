defmodule Helix.Account.Controller.AccountSettingTest do

  use ExUnit.Case, async: true

  alias Helix.Account.Controller.AccountSetting, as: AccountSettingController
  alias Helix.Account.Model.Account
  alias Helix.Account.Model.Setting
  alias Helix.Account.Repo

  alias Helix.Account.Factory

  # returns a diff containing any custom setting, this is needed to test that
  # fetching every setting from an account with no custom setting is valid
  defp reject_unchanged_settings(account_settings) do
    account_kv_set =
      account_settings
      |> Enum.to_list()
      |> MapSet.new()

    default_kv_set =
      Setting
      |> Repo.all()
      |> Enum.map(&({&1.setting_id, &1.default_value}))
      |> MapSet.new()

    default_kv_set
    |> MapSet.difference(account_kv_set)
    |> MapSet.to_list()
  end

  describe "changing specific settings" do
    test "succeeds with valid params" do
      %{account: account, setting_id: sid, setting_value: val} =
        Factory.params(:account_setting)

      {:ok, put_result} = AccountSettingController.put(account, sid, val)
      {:ok, get_result} = AccountSettingController.get(account, sid)

      # put yields sent value
      assert val == put_result

      # put and get yields the same value
      assert get_result == put_result
    end

    test "fails when setting is invalid" do
      %{setting_id: sid} = Factory.build(:setting)
      %{account: a, setting_value: val} = Factory.params(:account_setting)

      assert {:error, cs} = AccountSettingController.put(a, sid, val)
      assert :setting_id in Keyword.keys(cs.errors)
    end
  end

  describe "fetching specific settings" do
    test "returns custom value when setting is changed" do
      account_setting = Factory.insert(:account_setting)
      account = Repo.get_by(Account, account_id: account_setting.account_id)
      sid = account_setting.setting_id

      {:ok, get_result} = AccountSettingController.get(account, sid)

      assert account_setting.setting_value == get_result
    end

    test "returns default value when setting is unchanged" do
      %{setting_id: sid, default_value: default_value} =
        Factory.insert(:setting)

      account = Factory.insert(:account)
      {:ok, account_value} = AccountSettingController.get(account, sid)

      assert default_value == account_value
    end
  end

  describe "fetching every setting" do
    test "fetches settings with custom values" do
      account = Factory.insert(:account)
      custom_settings = Factory.settings_for(account)

      assert custom_settings == AccountSettingController.get_settings(account)
    end

    test "fetches unchanged settings" do
      account = Factory.insert(:account)
      account_settings = AccountSettingController.get_settings(account)

      assert [] == reject_unchanged_settings(account_settings)
    end
  end
end