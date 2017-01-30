defmodule Helix.Account.Model.AccountSettingTest do

  use ExUnit.Case, async: true

  alias HELL.TestHelper.Random
  alias Helix.Account.Model.AccountSetting

  test "fields account_id, setting_id and setting_value are required" do
    params = %{
      account_id: Random.pk(),
      setting_id: Random.string(),
      setting_value: Random.string()
    }

    cs1 = AccountSetting.create_changeset(params)
    cs2 = AccountSetting.create_changeset(%{})
    errors = Enum.sort(Keyword.keys(cs2.errors))
    expected = Enum.sort([:account_id, :setting_id, :setting_value])

    assert expected == errors
    assert cs1.valid?
  end
end