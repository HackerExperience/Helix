defmodule Helix.Account.Model.AccountSettingTest do

  use ExUnit.Case, async: true

  alias HELL.PK
  alias Helix.Account.Model.Account
  alias Helix.Account.Model.AccountSetting

  alias Helix.Account.Factory

  defp generate_params do
    s = Factory.build(:account_setting)

    %{
      account_id: PK.pk_for(Account),
      setting_id: s.setting.setting_id,
      setting_value: s.setting_value
    }
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