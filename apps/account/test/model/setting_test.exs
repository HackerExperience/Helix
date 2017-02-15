defmodule Helix.Account.Model.SettingTest do

  use ExUnit.Case, async: true

  alias Helix.Account.Model.Setting

  alias Helix.Account.Factory

  def generate_params do
    :setting
    |> Factory.build()
    |> Map.from_struct()
    |> Map.drop([:__meta__])
  end

  test "fields setting_id and default_value are required" do
    params = generate_params()

    IO.inspect(Factory.params_for(:setting))

    cs1 = Setting.create_changeset(params)
    cs2 = Setting.create_changeset(%{})

    errors = Enum.sort(Keyword.keys(cs2.errors))
    expected = Enum.sort([:setting_id, :default_value])

    assert expected == errors
    assert cs1.valid?
  end
end