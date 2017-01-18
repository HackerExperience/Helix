defmodule HELL.MacAddress do

  @type t :: String.t

  @behaviour Ecto.Type

  def type,
    do: :macaddr

  def cast(mac = %Postgrex.MACADDR{}),
    do: {:ok, to_string(mac)}
  def cast(string) when is_binary(string) do
    valid_addr?(string)
    && {:ok, string}
    || :error
  end

  def cast(_) do
    :error
  end

  def load(mac = %Postgrex.MACADDR{}),
    do: {:ok, to_string(mac)}
  def load(_),
    do: :error

  def dump(mac = %Postgrex.MACADDR{}),
    do: {:ok, mac}
  def dump(string) when is_binary(string),
    do: parse_address(string)
  def dump(_),
    do: :error

  @spec parse_address(String.t) :: {:ok, Postgrex.MACADDR.t} | :error
  defp parse_address(string) when is_binary(string) do
    addr =
      string
      |> String.split(":")
      |> Enum.map(&String.to_integer(&1, 16))
      |> List.to_tuple()

    {:ok, %Postgrex.MACADDR{address: addr}}
  end

  def valid_addr?(string),
    do: valid_addr?(string, :one, 17)

  @hex Enum.to_list(?0..?9) ++ Enum.to_list(?A..?F)
  defp valid_addr?("", :colon, 0),
    do: true
  for x <- @hex do
    defp valid_addr?(unquote(<<x>>) <> t, :one, n),
      do: valid_addr?(t, :two, n - 1)
    defp valid_addr?(unquote(<<x>>) <> t, :two, n),
      do: valid_addr?(t, :colon, n - 1)
  end
  defp valid_addr?(":" <> t, :colon, n),
    do: valid_addr?(t, :one, n - 1)
  defp valid_addr?(_, _, _),
    do: false
end

defimpl String.Chars, for: Postgrex.MACADDR do
  def to_string(%Postgrex.MACADDR{address: address_tuple}) do
    address_tuple
    |> Tuple.to_list()
    |> Enum.map_join(":", &Integer.to_string(&1, 16))
  end
end