defmodule Helix.Test.Notification.Helper do

  def expected_suffix(:account),
    do: 1
  def expected_suffix(:server),
    do: 2

  def get_suffix(%{id: {_, suffix, _, _, _, _, _, _}}),
    do: suffix
end
