defmodule HELL.Constant do

  @type t :: atom

  def type,
    do: :string

  def cast(constant) when is_atom(constant),
    do: {:ok, constant}
  def cast(_),
    do: :error

  def load(constant) when is_binary(constant),
    do: {:ok, String.to_existing_atom(constant)}
  def load(_),
    do: :error

  def dump(constant) when is_atom(constant),
    do: {:ok, Atom.to_string(constant)}
  def dump(_),
    do: :error
end
