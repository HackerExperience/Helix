defmodule Helix.Account.Model.SettingTest do

  use ExUnit.Case, async: true

  alias Helix.Account.Model.Setting

  @moduletag :unit

  test "enforces field typing" do
    result = Setting.changeset(%{is_beta: "invalid"})

    refute result.valid?
    refute :unknown_setting in Keyword.keys(result.errors)
  end

  test "ignores unknown settings" do
    result =
      %{unknown_setting: "Example"}
      |> Setting.changeset()
      |> Ecto.Changeset.apply_changes()
      |> Map.from_struct()
      |> Map.keys()

    refute :unknown_setting in result
  end

  test "casts default settings to nil" do
    result =
      Setting.default()
      |> Map.from_struct()
      |> Setting.changeset()
      |> Ecto.Changeset.apply_changes()
      |> Map.from_struct()
      |> Enum.reject(fn {_, v} -> is_nil(v) end)

    assert Enum.empty?(result)
  end
end
