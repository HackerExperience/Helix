defmodule HELL.Random do

  def random_string(length) do
    random_bytes(length)
    |> Base.encode32(case: :lower)
    |> String.slice(0 .. length - 1)
  end

  defp random_bytes(n) do
    :crypto.strong_rand_bytes(n)
  end
end
