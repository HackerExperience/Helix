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
    do: from_string(ltree)
  def dump(_),
    do: :error

  defp to_list(str),
    do: {:ok, String.split(str, ".")}

  defp from_string(list),
    do: from_string(list, "")

  defp from_string([head | []], acc) do
    if acc != "" and is_valid?(head) do
      {:ok, acc <> head}
    else
      :error
    end
  end
  defp from_string([head | tail], acc) do
    if is_valid?(head) do
      acc = if acc != "", do: acc <> head <> ".", else: head <> "."
      from_string(tail, acc)
    else
      :error
    end
  end

  valid_chars =
    [?a..?z, ?A..?Z, ?0..?9]
    |> Enum.map(&Enum.to_list/1)
    |> Enum.reduce([], &(&2 ++ &1))
    |> Kernel.++([?_])

  for c <- valid_chars do
    defp is_valid?(<<unquote(c)>>),
      do: true
    defp is_valid?(<<unquote(c), tail::binary>>),
      do: is_valid?(tail)
  end

  defp is_valid?(_),
    do: false
end