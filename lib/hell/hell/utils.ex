defmodule HELL.Utils do

  @doc """
  Generates a date in the future, according to the given precision. Defaults to
  seconds.
  """
  def date_after(seconds, precision \\ :second) do
    DateTime.utc_now()
    |> DateTime.to_unix(precision)
    |> Kernel.+(seconds)
    |> DateTime.from_unix!(precision)
  end

  @doc """
  Generates a date in the past, according to the given precision. Defaults to
  seconds.
  """
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

  @doc """
  Concatenates two elements, returning an atom.
  """
  def concat_atom(a, b) when is_atom(a) and is_atom(b),
    do: concat_atom(Atom.to_string(a), Atom.to_string(b))
  def concat_atom(a, b) when is_binary(a) and is_atom(b),
    do: concat_atom(a, Atom.to_string(b))
  def concat_atom(a, b) when is_atom(a) and is_binary(b),
    do: concat_atom(Atom.to_string(a), b)
  def concat_atom(a, b) when is_binary(a) and is_binary(b),
    do: String.to_atom(a <> b)

  @doc """
  Concatenates two strings. It's a more readable option to Kernel.<>/2, intended
  to be used on pipes.
  """
  def concat(a, b) when is_binary(a) and is_binary(b),
    do: a <> b

  def atom_contains?(a, value) when is_atom(a) do
    a
    |> Atom.to_string()
    |> String.contains?(value)
  end
end
