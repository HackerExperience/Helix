defmodule Helix.Process.Resources.Utils do

  def ensure_float(i) when is_number(i),
    do: i / 1 |> Float.round(3)
  def ensure_float(map) when map_size(map) == 0,
    do: 0.0

  # We should never reach this function!! Left here as a temporary workaround.
  # (We all know how these "temporary" workarounds work...)
  def ensure_float(i) do
    Enum.map(i, fn {_k, v} ->
      ensure_float(v)
    end)
    |> List.first()
  end
end
