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

  @doc """
  Similar to `String.upcase`, but applied to an atom.
  """
  def upcase_atom(a) when is_atom(a) do
    a
    |> Atom.to_string()
    |> String.upcase()
    |> String.to_atom()
  end

  @doc """
  Similar to `String.downcase`, but applied to an atom.
  """
  def downcase_atom(a) when is_atom(a) do
    a
    |> Atom.to_string()
    |> String.downcase()
    |> String.to_atom()
  end

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

  @spec stringify(term) ::
    String.t
    | nil
  @doc """
  `stringify/1` is exactly the same thing as `to_string/1`, except it won't
  convert `nil` values to `""`. `nil` values will keep being `nil`.
  """
  def stringify(nil),
    do: nil
  def stringify(value),
    do: to_string(value)

  @doc """
  `stringify_map/1` will convert all values from an arbitrarily-nested map into a
  string.
  """
  def stringify_map(helix_id = %_{id: _, root: _}),
    do: to_string(helix_id)
  def stringify_map(val) when is_number(val),
    do: val
  def stringify_map(val) when is_binary(val),
    do: val
  def stringify_map(val) when is_atom(val),
    do: to_string(val)
  def stringify_map(map) when is_map(map) do
    Enum.reduce(map, %{}, fn {k, v}, acc ->
      %{}
      |> Map.put(k, stringify_map(v))
      |> Map.merge(acc)
    end)
  end
end
