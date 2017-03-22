defmodule Helix.Account.Model.SettingTest do

  use ExUnit.Case, async: true

  alias Helix.Account.Model.Setting

  alias Helix.Account.Factory

  @moduletag :unit

  defp generate_params do
    s = Factory.build(:setting)

    %{
      setting_id: s.setting_id,
      default_value: s.default_value
    }
  end

  test "fields setting_id and default_value are required" do
    params = generate_params()

    cs1 = Setting.create_changeset(params)
    cs2 = Setting.create_changeset(%{})

    errors = Enum.sort(Keyword.keys(cs2.errors))
    expected = Enum.sort([:setting_id, :default_value])

    assert expected == errors
    assert cs1.valid?
  end
end