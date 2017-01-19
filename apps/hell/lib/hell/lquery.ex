defmodule HELL.LQuery do
  @moduledoc """
  `Ecto.Type` for `lquery`, accepts and validates `[String.t]`.
  Also accepts `String.t`, but no validation is made.

  The validation won't check the syntax, just the characters.
  """

  @type t :: String.t

  @behaviour Ecto.Type

  defdelegate serialize(list, mode), to: HELL.LTree

  def type,
    do: :lquery

  @doc """
  Cast accept lists and binaries, but won't validate anything.
  """
  def cast(list) when is_list(list),
    do: {:ok, list}
  def cast(string) when is_binary(string) do
    list = String.split(string, ".")
    {:ok, list}
  end
  def cast(_),
    do: :error

  @doc """
  Load will convert the binary back to list by splitting, it won't validate
  anything since it expects to always receive data previously validated by dump.
  """
  def load(string) when is_binary(string),
    do: cast(string)
  def load(_),
    do: :error

  @doc """
  Dump accepts will validate while it converts the list into a binarie.
  """
  def dump(list) when is_list(list),
    do: serialize(list, :lquery)
  def dump(_),
    do: :error
end