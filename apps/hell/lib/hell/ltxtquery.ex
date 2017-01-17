defmodule HELL.LTXTQuery do

  @type t :: String.t

  @behaviour Ecto.Type

  def type,
    do: :ltxtquery

  def cast(ltxtquery) when is_binary(ltxtquery),
    do: {:ok, ltxtquery}
  def cast(_),
    do: :error

  def load(ltxtquery) when is_binary(ltxtquery),
    do: {:ok, ltxtquery}
  def load(_),
    do: :error

  def dump(ltxtquery) when is_binary(ltxtquery),
    do: {:ok, ltxtquery}
  def dump(_),
    do: :error
end