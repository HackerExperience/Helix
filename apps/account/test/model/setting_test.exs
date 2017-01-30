defmodule Helix.Account.Model.SettingTest do

  use ExUnit.Case, async: true

  alias HELL.TestHelper.Random
  alias Helix.Account.Model.Setting

  test "fields setting_id and default_value are required" do
    params = %{
      setting_id: Random.setting_id(),
      default_value: Random.string()
    }

    cs1 = Setting.create_changeset(params)
    cs2 = Setting.create_changeset(%{})
    errors = Enum.sort(Keyword.keys(cs2.errors))
    expected = Enum.sort([:setting_id, :default_value])

    assert expected == errors
    assert cs1.valid?
  end
end