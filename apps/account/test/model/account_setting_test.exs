defmodule Helix.Account.Model.AccountSettingTest do

  use ExUnit.Case, async: true

  alias Helix.Account.Model.AccountSetting

  alias Helix.Account.Factory

  def generate_params do
    account_setting =
      :account_setting
      |> Factory.build()
      |> Map.from_struct()
      |> Map.drop([:__meta__])

    account_setting
    |> Map.put(:account_id, account_setting.account.account_id)
    |> Map.put(:setting_id, account_setting.setting.setting_id)
  end

  test "fields account_id, setting_id and setting_value are required" do
    params = generate_params()

    cs1 = AccountSetting.create_changeset(params)
    cs2 = AccountSetting.create_changeset(%{})
    errors = Enum.sort(Keyword.keys(cs2.errors))
    expected = Enum.sort([:account_id, :setting_id, :setting_value])

    assert expected == errors
    assert cs1.valid?
  end
end