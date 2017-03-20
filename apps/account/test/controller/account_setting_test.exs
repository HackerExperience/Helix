defmodule Helix.Account.Controller.AccountSettingTest do

  use ExUnit.Case, async: true

  alias HELL.TestHelper.Random
  alias Helix.Account.Controller.AccountSetting, as: AccountSettingController
  alias Helix.Account.Model.Setting
  alias Helix.Account.Repo

  alias Helix.Account.Factory

  setup_all do
    if Repo.all(Setting) == [],
      do: Factory.insert_list(3, :setting)
    :ok
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
    test "includes default and modified settings" do
      account = Factory.insert(:account)
      settings = Repo.all(Setting)
      value = Random.string()

      settings
      |> Enum.take_random(3)
      |> Enum.each(&AccountSettingController.put(account, &1.setting_id, value))

      account_settings = AccountSettingController.get_settings(account)
      defaults = Enum.into(settings, %{}, &{&1.setting_id, &1.default_value})
      diff = Map.values(account_settings) -- Map.values(defaults)

      assert Map.keys(account_settings) == Map.keys(defaults)
      assert 3 == Enum.count(diff)
    end

    test "includes every unchanged setting" do
      account = Factory.insert(:account)

      account_settings = AccountSettingController.get_settings(account)
      default_settings =
        Setting
        |> Repo.all()
        |> Enum.into(%{}, &{&1.setting_id, &1.default_value})

      assert account_settings == default_settings
    end
  end
end