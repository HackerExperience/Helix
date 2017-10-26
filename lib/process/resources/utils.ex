defmodule Helix.Process.Resources.Utils do

  def ensure_float(i) when is_number(i),
    do: i / 1 |> Float.round(3)
  def ensure_float(i),
    do: i
end
