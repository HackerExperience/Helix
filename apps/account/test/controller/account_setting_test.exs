defmodule Helix.Account.Controller.AccountSettingTest do

  use ExUnit.Case, async: true

  alias Helix.Account.Controller.AccountSetting, as: AccountSettingController
  alias Helix.Account.Model.AccountSetting
  alias Helix.Account.Model.Setting
  alias Helix.Account.Repo

  alias Helix.Account.Factory

  setup_all do
    if Repo.all(Setting) == [],
      do: Factory.insert_list(3, :setting)
    :ok
  end

  defp format_settings(settings, mapper \\ nil) do
    Enum.into(settings, %{}, fn setting ->
      setting_tuple =
        case setting do
          setting = %Setting{} ->
            {setting.setting_id, setting.default_value}
          setting = %AccountSetting{} ->
            {setting.setting_id, setting.setting_value}
          {setting_id, setting_value} ->
            {setting_id, setting_value}
        end

      if mapper,
        do: mapper.(setting_tuple),
        else: setting_tuple
    end)
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

      default_settings =
        Setting
        |> Repo.all()
        |> format_settings()

      expected_settings =
        Setting
        |> Repo.all()
        |> format_settings(fn {setting_id, _} ->
          %{setting_value: value} = Factory.params_for(:account_setting)
          {setting_id, value}
        end)

      Enum.each(expected_settings, fn {setting, value} ->
        AccountSettingController.put(account, setting, value)
      end)

      received_settings =
        account
        |> AccountSettingController.get_settings()
        |> format_settings()

      assert expected_settings == received_settings
      refute received_settings == default_settings
    end

    test "includes unchanged settings" do
      account = Factory.insert(:account)

      account_settings =
        account
        |> AccountSettingController.get_settings()
        |> format_settings()

      default_settings =
        Setting
        |> Repo.all()
        |> format_settings()

      assert account_settings == default_settings
    end
  end
end