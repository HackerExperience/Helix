defmodule Helix.Account.Model.SettingTest do

  use ExUnit.Case, async: true

  alias Helix.Account.Model.Setting

  @moduletag :unit

  test "enforces is_beta field boolean typing" do
    bogus = Setting.changeset(%{is_beta: "invalid"})

    refute bogus.valid?
    assert :is_beta in Keyword.keys(bogus.errors)
  end
end
