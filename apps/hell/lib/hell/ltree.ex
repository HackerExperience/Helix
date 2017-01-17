defmodule HELL.LTree do

  @type t :: String.t

  @behaviour Ecto.Type

  def type,
    do: :ltree

  def cast(ltree) when is_binary(ltree),
    do: {:ok, ltree}
  def cast(_),
    do: :error

  def load(ltree) when is_binary(ltree),
    do: {:ok, ltree}
  def load(_),
    do: :error

  def dump(ltree) when is_binary(ltree),
    do: {:ok, ltree}
  def dump(_),
    do: :error
end