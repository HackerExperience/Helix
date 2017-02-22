defmodule HELL.TestHelper.Helpers do

  def list_diff(from, list) do
    from_set = MapSet.new(from)

    list
    |> MapSet.new()
    |> MapSet.difference(from_set)
    |> MapSet.to_list()
  end
end