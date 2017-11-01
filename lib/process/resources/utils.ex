defmodule Helix.Process.Resources.Utils do

  def ensure_float(i) when is_number(i),
    do: i / 1 |> Float.round(3)
  def ensure_float(map) when map_size(map) == 0,
    do: 0.0

  def safe_div(dividend, divisor, _initial) when divisor > 0,
    do: dividend / divisor
  def safe_div(_, 0.0, initial),
    do: initial.()
  def safe_div(_, 0, initial),
    do: initial.()
end
