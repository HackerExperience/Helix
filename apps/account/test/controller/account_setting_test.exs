defmodule Helix.Account.Controller.AccountSettingTest do

  use ExUnit.Case, async: true

  alias HELL.TestHelper.Random
  alias Helix.Account.Controller.Account, as: AccountController
  alias Helix.Account.Controller.AccountSetting, as: AccountSettingController
  alias Helix.Account.Model.Setting
  alias Helix.Account.Repo

  defp create_account() do
    username = Random.username()
    email = Burette.Internet.email()
    password = Burette.Internet.password()
    params = %{
      username: username,
      email: email,
      password_confirmation: password,
      password: password
    }

    {:ok, account} = AccountController.create(params)
    account
  end

  def create_setting() do
    setting_id = Random.setting_id()
    default_value = Burette.Color.name()

    %{setting_id: setting_id, default_value: default_value}
    |> Setting.create_changeset()
    |> Repo.insert()

    setting_id
  end

  setup_all do
    setting_id = create_setting()
    {:ok, setting_id: setting_id}
  end

  describe "configuring user settings" do
    test "succeeds when setting exists", context do
        id = context.setting_id
        custom_val = Random.string(min: 10)
        account = create_account()

        {:ok, put_value} = AccountSettingController.put(account, id, custom_val)
        {:ok, get_value} = AccountSettingController.get(account, id)

        %{default_value: default} = Repo.get_by(Setting, setting_id: id)

        # got expected value from put
        assert custom_val == put_value

        # default value differs from put value
        refute default == put_value

        # both values from put and get are equals
        assert put_value == get_value
    end

    test "fails when setting is invalid" do
      id = Random.setting_id()
      custom_val = Random.string(min: 10)
      account = create_account()

      assert {:error, cs} = AccountSettingController.put(account, id, custom_val)
      assert :setting_id in Keyword.keys(cs.errors)
    end
  end

  describe "fetching account settings" do
    test "returns account's setting by account and setting id", context do
      id = context.setting_id
      custom_val = Random.string(min: 10)

      account = create_account()
      {:ok, before_change} = AccountSettingController.get(account, id)

      AccountSettingController.put(account, id, custom_val)

      {:ok, after_change} = AccountSettingController.get(account, id)

      %{default_value: default} = Repo.get_by(Setting, setting_id: id)

      # fetched default value prior to updating it
      assert default == before_change

      # value changed
      refute before_change == after_change

      # value fecthed after change is the expected value
      assert custom_val == after_change
    end

    test "returns default value when setting is not defined for account", context do
      id = context.setting_id

      account = create_account()
      {:ok, setting_value} = AccountSettingController.get(account, id)

      %{default_value: default} = Repo.get_by(Setting, setting_id: id)

      # fetched expected value
      assert default == setting_value
    end

    test "fails when setting doesn't exist" do
      id = Random.setting_id()
      account = create_account()

      assert {:error, :notfound} == AccountSettingController.get(account, id)
    end
  end

  describe "fetching every setting" do
    test "fetches settings with custom values" do
      a = create_account()
      s = Enum.map(0..5, fn _ ->
        id = create_setting()
        custom_val = Random.string(min: 10)

        {id, custom_val}
      end)

      Enum.each(s, fn {k, v} -> AccountSettingController.put(a, k, v) end)

      custom_settings = MapSet.new(s)

      settings =
        a
        |> AccountSettingController.get_settings()
        |> Enum.to_list()
        |> MapSet.new()

      assert MapSet.subset?(custom_settings, settings)
    end

    test "fallbacks to default setting value" do
      a = create_account()
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