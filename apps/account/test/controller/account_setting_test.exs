defmodule Helix.Account.Controller.AccountSettingTest do

  use ExUnit.Case, async: true

  alias Helix.Account.Controller.AccountSetting, as: AccountSettingController
  alias Helix.Account.Model.Setting
  alias Helix.Account.Repo

  alias Helix.Account.Factory

  import Ecto.Query, only: [select: 3]

  defp diff_settings(account_settings, method) do
    diff =
      case method do
        :changed ->
          &MapSet.difference/2
        :unchanged ->
          &MapSet.intersection/2
      end

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
    |> diff.(account_kv_set)
    |> Enum.map(fn {k, _} -> k end)
  end

  defp to_custom_settings_map(settings) do
    custom_settings =
      Enum.map(settings, fn setting ->
        %{setting_value: value} = Factory.params_for(:account_setting)
        {setting, value}
      end)

    :maps.from_list(custom_settings)
  end

  describe "changing specific settings" do
    test "succeeds with valid params" do
      account = Factory.insert(:account)
      setting = Factory.insert(:setting)
      %{setting_value: value} = Factory.params_for(:account_setting)

      {:ok, put_result} = AccountSettingController.put(account, setting, value)
      {:ok, get_result} = AccountSettingController.get(account, setting)

      # put yields sent value
      assert value == put_result

      # put and get yields the same value
      assert get_result == put_result
    end

    test "fails when setting is invalid" do
      account = Factory.insert(:account)
      setting = Factory.build(:setting)
      %{setting_value: val} = Factory.params_for(:account_setting)

      assert {:error, cs} = AccountSettingController.put(account, setting, val)
      assert :setting_id in Keyword.keys(cs.errors)
    end
  end

  describe "fetching specific settings" do
    test "returns custom value when setting is changed" do
      account = Factory.insert(:account)
      setting = Factory.insert(:setting)
      %{setting_value: value} = Factory.params_for(:account_setting)

      AccountSettingController.put(account, setting, value)

      {:ok, return} = AccountSettingController.get(account, setting)

      assert value === return
    end

    test "returns default value when setting is unchanged" do
      account = Factory.insert(:account)
      setting = Factory.insert(:setting)

      {:ok, setting_value} = AccountSettingController.get(account, setting)

      assert setting.default_value == setting_value
    end
  end

  describe "fetching every setting" do
    test "includes modified settings" do
      account = Factory.insert(:account)

      custom_settings =
        Setting
        |> select([s], s.setting_id)
        |> Repo.all()
        |> to_custom_settings_map()

      Enum.each(custom_settings, fn {setting, value} ->
        AccountSettingController.put(account, setting, value)
      end)

      assert custom_settings == AccountSettingController.get_settings(account)
      assert [] == diff_settings(custom_settings, :unchanged)
    end

    test "includes unchanged settings" do
      account = Factory.insert(:account)
      account_settings = AccountSettingController.get_settings(account)

      assert [] == diff_settings(account_settings, :changed)
    end
  end
end