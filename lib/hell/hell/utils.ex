defmodule HELL.Utils do
  def date_after(seconds, precision \\ :second) do
    DateTime.utc_now()
    |> DateTime.to_unix(precision)
    |> Kernel.+(seconds)
    |> DateTime.from_unix!(precision)
  end

  def date_before(seconds, precision \\ :second),
    do: date_after(-seconds, precision)
end
