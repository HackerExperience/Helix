defmodule HELL.TestHelper.Random.Alphabet do
  @moduledoc """
  Represents an alphabet to be used by `HELL.TestHelper.Random.string/1`
  """

  defstruct [:size, :characters]

  def build_alphabet(characters) do
    {chars, size} =
      characters
      |> string_to_list()
      |> Enum.with_index()
      |> Enum.map_reduce(0, fn {char, index}, _ -> {{index, char}, index} end)

    %__MODULE__{
      size: size,
      characters: Enum.into(chars, %{})}
  end

  defp string_to_list(collection = [_|_]),
    do: collection
  defp string_to_list(string) when is_binary(string),
    do: string_to_list(string, [])
  defp string_to_list(<<h::utf8, t::binary>>, acc),
    do: string_to_list(t, [<<h::utf8>>| acc])
  defp string_to_list("", acc),
    do: acc
end