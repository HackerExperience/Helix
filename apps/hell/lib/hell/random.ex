defmodule HELL.Random do
  def random_number(max_len \\ 134217727) do
    :rand.uniform(max_len)
  end

  def random_numeric_string(max_len \\ nil) do
    case max_len do
      nil -> random_number()
      num -> random_number(num)
    end
    |> Integer.to_string()
  end

  def random_string(length) do
    random_bytes(length)
    |> Base.encode32(case: :lower)
    |> String.slice(0 .. length - 1)
  end

  def random_bytes(n) do
    :crypto.strong_rand_bytes(n)
  end
end
