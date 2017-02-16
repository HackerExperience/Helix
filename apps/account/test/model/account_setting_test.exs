defmodule Helix.Account.Model.AccountSettingTest do

  use ExUnit.Case, async: true

  alias Helix.Account.Model.AccountSetting

  alias Helix.Account.Factory

  test "fields account_id, setting_id and setting_value are required" do
    params = Factory.params(:account_setting)

    cs1 = AccountSetting.create_changeset(params)
    cs2 = AccountSetting.create_changeset(%{})

    errors = Enum.sort(Keyword.keys(cs2.errors))
    expected = Enum.sort([:account_id, :setting_id, :setting_value])

    assert expected == errors
    assert cs1.valid?
  end
end