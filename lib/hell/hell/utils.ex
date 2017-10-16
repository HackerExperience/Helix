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

  @spec concat_atom(atom | String.t, atom | String.t) ::
    atom
  @doc """
  Concatenates two elements, returning an atom.
  """
  def concat_atom(a, b) when is_atom(a),
    do: concat_atom(Atom.to_string(a), b)
  def concat_atom(a, b) when is_atom(b),
    do: concat_atom(a, Atom.to_string(b))
  def concat_atom(a, b) when is_binary(a) and is_binary(b),
    do: String.to_atom(a <> b)

  @spec concat(atom | String.t, atom | String.t) ::
    String.t
  @doc """
  Concatenates two strings. It's a more readable option to Kernel.<>/2, intended
  to be used on pipes. It can also handle concatenation of atoms, in which case
  this function will always return a string. See also `concat_atom/2`.
  """
  def concat(a, b) when is_atom(a),
    do: concat(Atom.to_string(a), b)
  def concat(a, b) when is_atom(b),
    do: concat(a, Atom.to_string(b))
  def concat(a, b) when is_binary(a) and is_binary(b),
    do: a <> b

  def concat(a, b, c),
    do: concat(a, b) |> concat(c)

  @spec atom_contains?(atom, String.t) ::
    boolean
  @doc """
  `String.contains?` applied to an atom.
  """
  def atom_contains?(atom, value) when is_atom(atom) do
    atom
    |> Atom.to_string()
    |> String.contains?(value)
  end
end
