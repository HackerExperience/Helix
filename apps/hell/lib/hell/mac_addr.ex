defmodule HELL.MacAddress do

  @type t :: String.t

  @behaviour Ecto.Type

  def generate do
    6
    |> generate_octets()
    |> Enum.map(&Integer.to_string(&1, 16))
    |> Enum.map_join(":", &String.pad_leading(&1, 2, "0"))
  end

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

  # The binary pattern ensures that the string contains 136 bits (ie: 17 ASCII
  # chars)
  def valid_addr?(string = <<_ :: size(136)>>),
    do: valid_addr?(string, :one)
  def valid_addr?(_),
    do: false

  @hex ~w/0 1 2 3 4 5 6 7 8 9 A B C D E F/
  @permutations for x <- @hex, {y, z} <- [{:one, :two}, {:two, :colon}], do: {x, y, z}
  @permutations [{":", :colon, :one}| @permutations]

  for {char, from, to} <- @permutations do
    # If the current `char` is in the range of `@hex` and the state is :one, it
    # moves to :two; if the state is :two, it moves to :colon;
    # If the current char is `":"` and the state is :colon, it moves to :one
    # If there is no char left, the input string is a valid maccaddr
    # Otherwise it is not a valid macaddr
    defp valid_addr?(unquote(char) <> t, unquote(from)),
      do: valid_addr?(t, unquote(to))
  end

  defp valid_addr?("", :colon),
    do: true
  defp valid_addr?(_, _),
    do: false

  @spec generate_octets(pos_integer) :: [0..0xff]
  defp generate_octets(octets) do
    octets
    |> :crypto.strong_rand_bytes()
    |> :erlang.binary_to_list()
  rescue
    ErlangError ->
      for _ <- 1..octets do
        # Generates a random number between 0x00 and 0xff
        ((0xff + 1) * :rand.uniform())
        |> Float.floor()
        |> trunc()
      end
  end
end

defimpl String.Chars, for: Postgrex.MACADDR do
  def to_string(%Postgrex.MACADDR{address: address_tuple}) do
    address_tuple
    |> Tuple.to_list()
    |> Enum.map_join(":", &Integer.to_string(&1, 16))
  end
end