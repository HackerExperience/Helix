defmodule HELL.Utils do

  def date_after(seconds, precision \\ :second) do
    DateTime.utc_now()
    |> DateTime.to_unix(precision)
    |> Kernel.+(seconds)
    |> DateTime.from_unix!(precision)
  end

  def date_before(seconds, precision \\ :second),
    do: date_after(-seconds, precision)

  @doc """
  Helper to ensure the given value is returned as a list.
  """
  def ensure_list(nil),
    do: []
  def ensure_list(value) when is_list(value),
    do: value
  def ensure_list(value),
    do: [value]

end
