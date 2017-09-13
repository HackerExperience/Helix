defmodule Helix.Test.Case.Cache do

  import ExUnit.Assertions

  def assert_miss(query) do
    assert {:miss, _} = query
  end
  def assert_miss(query, reason) do
    assert {:miss, reason} == query
  end

  def assert_hit(query) do
    assert {:hit, result} = query
    result
  end
end
