defmodule HELL.LQuery do

  @type t :: String.t

  @behaviour Ecto.Type

  def type,
    do: :lquery

  def cast(lquery) when is_binary(lquery),
    do: {:ok, lquery}
  def cast(_),
    do: :error

  def load(lquery) when is_binary(lquery),
    do: {:ok, lquery}
  def load(_),
    do: :error

  def dump(lquery) when is_binary(lquery),
    do: {:ok, lquery}
  def dump(_),
    do: :error
end