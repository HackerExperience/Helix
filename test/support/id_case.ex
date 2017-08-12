defmodule Helix.Test.IDCase do

  import ExUnit.Assertions

  def assert_id(a = %_{id: _}, b = %_{id: _}) do
    assert a == b
  end

  @doc """
  Asserts two maps are identical to each other, even if one uses ID and the
  other uses binary/PK.

  Pseudo example:

    nip1 = %{network_id: "::", ip: "1.2.3.4"}
    nip2 = %{network_id: Network.ID{...}, ip: "1.2.3.4"}`
    assert_id nip1, nip2  # true
  """
  def assert_id(a, b) when is_map(a) and is_map(b) do
    Enum.each(a, fn({k, v}) ->
      assert_id v, Map.get(b, k)
    end)
  end

  def assert_id(a, b) when is_list(a) and is_list(b) do
    Enum.zip(a, b)
    |> Enum.each(fn {a, b} ->
      assert_id(a, b)
    end)
  end

  def assert_id(a, b) do
    assert to_string(a) == to_string(b)
  end
end
