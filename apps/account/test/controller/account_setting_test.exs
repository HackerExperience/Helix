defmodule Helix.Account.Controller.AccountSettingTest do

  use ExUnit.Case, async: true

  alias Helix.Account.Controller.AccountSetting, as: AccountSettingController
  alias Helix.Account.Model.Setting
  alias Helix.Account.Repo

  alias Helix.Account.Factory

  defp override_settings(account) do
    account
    |> AccountSettingController.get_settings()
    |> Enum.map(fn {setting_id, _} ->
      %{default_value: custom_value} = Factory.params(:setting)
      AccountSettingController.put(account, setting_id, custom_value)

      {setting_id, custom_value}
    end)
    |> Enum.into(%{})
  end

  defp default_settings?(account_settings) do
    account_kv_set =
      account_settings
      |> Enum.to_list()
      |> MapSet.new()

    default_kv_set =
      Setting
      |> Repo.all()
      |> Enum.map(&({&1.setting_id, &1.default_value}))
      |> MapSet.new()

    default_kv_set == account_kv_set
  end

  describe "changing and fetching specific settings" do
    test "returns default value when setting is unchanged" do
      %{setting_id: sid, default_value: default_value} =
        Factory.insert(:setting)

      account = Factory.insert(:account)
      {:ok, account_value} = AccountSettingController.get(account, sid)

      assert default_value == account_value
    end

    test "put changes setting value" do
      %{account: account, setting_id: sid, setting_value: val} =
        Factory.params(:account_setting)

      {:ok, put_result} = AccountSettingController.put(account, sid, val)
      {:ok, get_result} = AccountSettingController.get(account, sid)

      # put yields sent value
      assert val == put_result

      # put and get yields the same value
      assert put_result == get_result
    end

    test "fails to put when setting is invalid" do
      %{setting_id: sid} = Factory.build(:setting)
      %{account: a, setting_value: val} = Factory.params(:account_setting)

      assert {:error, cs} = AccountSettingController.put(a, sid, val)
      assert :setting_id in Keyword.keys(cs.errors)
    end
  end

  describe "fetching every setting" do
    test "fetches settings with custom values" do
      account = Factory.insert(:account)
      custom_settings = override_settings(account)

      assert custom_settings == AccountSettingController.get_settings(account)
    end

    test "fetches unchanged settings" do
      account = Factory.insert(:account)
      account_settings = AccountSettingController.get_settings(account)

      assert default_settings?(account_settings)
    end
  end
end