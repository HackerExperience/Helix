defmodule HELL.LTree do
  @moduledoc """
  `Ecto.Type` for `ltree`, accepts and validates `[String.t]`.
  Also accepts `String.t`, but no validation is made.
  """

  import HELL.MacroHelpers

  @type t :: String.t
  @type serialize_mode :: :ltree | :lquery | :ltxtquery

  @behaviour Ecto.Type

  def type,
    do: :ltree

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
    do: serialize(list, :ltree)
  def dump(_),
    do: :error

  @doc """
  Both joins and validates the list, this method is also used by `LQuery` and
  `LTXTQuery`.
  """
  @spec serialize([String.t], serialize_mode) :: {:ok, String.t} | :error
  def serialize(list, mode),
    do: serialize(list, mode, "")

  @spec serialize([String.t], serialize_mode, String.t) ::
    {:ok, String.t}
    | :error
  defp serialize([head | []], mode, acc) do
    if acc != "" and valid?(head, mode) do
      {:ok, acc <> head}
    else
      :error
    end
  end
  defp serialize([head | tail], mode, acc) do
    if valid?(head, mode) do
      acc = if acc != "", do: acc <> head <> ".", else: head <> "."
      serialize(tail, mode, acc)
    else
      :error
    end
  end
  defp serialize([], _, ""),
    do: :error

  # characters that are valid according to the mode
  lquery_chars = Enum.map([?@, ?*, ?%, ?|, ?!, ?{, ?}], &({&1, :lquery}))
  ltxtquery_chars = Enum.map([?\s, ?&], &({&1, :ltxtquery}))
  modal_chars = lquery_chars ++ ltxtquery_chars

  # characters that are always valid
  valid_chars =
    [?a..?z, ?A..?Z, ?0..?9]
    |> Enum.map(&(Enum.to_list/1))
    |> List.flatten()
    |> Kernel.++([?_])

  docp """
  Checks that the binary only contains valid ltree characters.
  """
  for c <- valid_chars do
    defp valid?(<<unquote(c)>>, _),
      do: true
    defp valid?(<<unquote(c), tail::binary>>, mode),
      do: valid?(tail, mode)
  end
  for {c, mode} <- modal_chars do
    defp valid?(<<unquote(c)>>, unquote(mode)),
      do: true
    defp valid?(<<unquote(c), tail::binary>>, unquote(mode)),
      do: valid?(tail, unquote(mode))
  end
  defp valid?(_, _),
    do: false
end