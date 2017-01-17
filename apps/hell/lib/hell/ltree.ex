defmodule HELL.LTree do

  @type t :: String.t

  @behaviour Ecto.Type

  def type,
    do: :ltree

  def cast(ltree) when is_list(ltree),
    do: {:ok, ltree}
  def cast(ltree) when is_binary(ltree),
    do: to_list(ltree)
  def cast(_),
    do: :error

  def load(ltree) when is_list(ltree),
    do: {:ok, ltree}
  def load(ltree) when is_binary(ltree),
    do: to_list(ltree)
  def load(_),
    do: :error

  def dump(ltree) when is_binary(ltree),
    do: {:ok, ltree}
  def dump(ltree) when is_list(ltree),
    do: from_list(ltree)
  def dump(_),
    do: :error

  defp to_list(str),
    do: {:ok, String.split(str, ".")}

  defp from_list(list),
    do: from_list(list, "")

  defp from_list([], accum),
    do: {:ok, accum}
  defp from_list([head | tail], accum) do
    case from_list(head, accum) do
      {:ok, accum} ->
        accum = if Enum.empty?(tail), do: accum, else: accum <> "."
        from_list(tail, accum)
      :error ->
        :error
    end
  end
  defp from_list("", _),
    do: :error
  defp from_list(str, accum),
    do: merge_valid(str, accum)

  defp merge_valid("", accum),
    do: {:ok, accum}

  valid_chars =
    [?_..?_, ?a..?z, ?A..?Z, ?0..?9]
    |> Enum.map(&Enum.to_list/1)
    |> Enum.reduce([], &(&2 ++ &1))

  for c <- valid_chars do
    defp merge_valid(<<unquote(c), tail::binary>>, accum),
      do: merge_valid(tail, accum <> <<unquote(c)>>)
  end

  defp merge_valid(_, _),
    do: :error
end