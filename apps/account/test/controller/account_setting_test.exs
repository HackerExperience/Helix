defmodule Helix.Account.Controller.AccountSettingTest do

  use ExUnit.Case, async: true

  alias Helix.Account.Controller.AccountSetting, as: AccountSettingController
  alias Helix.Account.Model.Setting
  alias Helix.Account.Repo

  alias Helix.Account.Factory

  def generate_params() do
    account_setting =
      :account_setting
      |> Factory.build()
      |> Map.from_struct()
      |> Map.drop([:__meta__])

    Repo.insert!(account_setting.account)
    Repo.insert!(account_setting.setting)

    account = account_setting.account
    setting_id = account_setting.setting.setting_id
    setting_value = account_setting.setting_value

    {account, setting_id, setting_value}
  end

  describe "configuring user settings" do
    test "succeeds when setting exists", _context do
      {a, s_id, val} = generate_params()
      {:ok, put_val} = AccountSettingController.put(a, s_id, val)
      {:ok, get_val} = AccountSettingController.get(a, s_id)

      %{default_value: default} = Repo.get_by(Setting, setting_id: s_id)

      # got expected value from put
      assert val == put_val

      # default value differs from put value
      refute default == put_val

      # both values from put and get are equals
      assert put_val == get_val
    end

    test "fails when setting is invalid" do
      {a, _, val} = generate_params()
      %{setting_id: s_id} = Factory.build(:setting)

      assert {:error, cs} = AccountSettingController.put(a, s_id, val)
      assert :setting_id in Keyword.keys(cs.errors)
    end
  end

  describe "fetching account settings" do
    test "returns account's setting by account and setting id" do
      {a, s_id, val} = generate_params()

      %{default_value: default} = Repo.get_by(Setting, setting_id: s_id)
      {:ok, maybe_default} = AccountSettingController.get(a, s_id)

      AccountSettingController.put(a, s_id, val)

      {:ok, maybe_not_default} = AccountSettingController.get(a, s_id)

      # fetched default value prior to updating it
      assert default == maybe_default

      # value changed
      assert val == maybe_not_default
    end

    test "returns default value when setting is not defined for account" do
      {a, s_id, _} = generate_params()
      {:ok, setting_value} = AccountSettingController.get(a, s_id)
      %{default_value: default} = Repo.get_by(Setting, setting_id: s_id)

      # fetched expected value
      assert default == setting_value
    end

    test "fails when setting doesn't exist" do
      {a, _, _} = generate_params()
      %{setting_id: s_id} = Factory.build(:setting)

      assert {:error, :notfound} == AccountSettingController.get(a, s_id)
    end
  end

  describe "fetching every setting" do
    test "fetches settings with custom values" do
      a = Factory.insert(:account)

      custom_settings =
        0..5
        |> Enum.map(fn _ ->
          account_setting = Factory.build(:account_setting)
          Repo.insert!(account_setting.setting)

          s_id = account_setting.setting.setting_id
          val = account_setting.setting_value

          {:ok, _} = AccountSettingController.put(a, s_id, val)

          {s_id, val}
        end)
        |> MapSet.new()

      settings =
        a
        |> AccountSettingController.get_settings()
        |> Enum.to_list()
        |> MapSet.new()

      assert MapSet.subset?(custom_settings, settings)
    end

    test "fallbacks to default setting value" do
      a = Factory.insert(:account)

      defaults =
        Setting
        |> Repo.all()
        |> Enum.map(&({&1.setting_id, &1.default_value}))
        |> MapSet.new()

      fetched =
        a
        |> AccountSettingController.get_settings()
        |> Enum.to_list()
        |> MapSet.new()

      assert MapSet.equal?(defaults, fetched)
    end
  end
end