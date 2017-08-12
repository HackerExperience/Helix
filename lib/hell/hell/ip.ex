defmodule HELL.IPv6 do

  use Bitwise

  @type t :: String.t

  @twooctet 0xffff
  @meta_groups 3
  @rand_groups 8 - @meta_groups

  @spec generate([non_neg_integer]) ::
    t
  def generate(metadata) do
    metadata
    |> fill_metadata()
    |> Enum.concat(generate_octet_groups(@rand_groups))
    |> List.to_tuple()
    |> :inet.ntoa()
    |> List.to_string()
  end

  @spec generate_address_tuple([0..0xffff, ...]) ::
    {
      0..0xffff,
      0..0xffff,
      0..0xffff,
      0..0xffff,
      0..0xffff,
      0..0xffff,
      0..0xffff,
      0..0xffff}
  def generate_address_tuple([a, b, c]) do
    [d, e, f, g, h] = generate_octet_groups(5)

    {a, b, c, d, e, f, g, h}
  end

  def binary_to_address_tuple(string) do
    string
    |> String.to_charlist()
    |> :inet.parse_ipv6strict_address()
  end

  @spec generate_octet_groups(pos_integer) ::
    [0..0xffff]
  defp generate_octet_groups(groups) do
    # Each group is comprised of 2 octets
    bytes = groups * 2

    bytes
    |> :crypto.strong_rand_bytes()
    |> partition_binary()
  rescue
    ErlangError ->
      for _ <- 1..groups do
        # Generates a random number between 0x0000 and 0xffff
        ((@twooctet + 1) * :rand.uniform())
        |> Float.floor()
        |> trunc()
      end
  end

  @spec partition_binary(String.t) ::
    [non_neg_integer]
  defp partition_binary(binary),
    do: partition_binary(binary, [])
  defp partition_binary(<<h1, h2, t::binary>>, acc),
    do: partition_binary(t, [h1 <<< 8 ||| h2| acc])
  defp partition_binary(<<>>, acc),
    do: acc

  @spec fill_metadata([non_neg_integer | String.t]) ::
    [non_neg_integer | String.t]
  defp fill_metadata(list),
    do: fill_metadata(list, 0)
  defp fill_metadata([], @meta_groups),
    do: []
  defp fill_metadata([h| t], n),
    do: [h| fill_metadata(t, n + 1)]
  defp fill_metadata([], n) when n < @meta_groups,
    do: [0x0000 | fill_metadata([], n + 1)]
end

defmodule HELL.IPv4 do

  @type t :: String.t

  def autogenerate do
    Enum.map_join(1..4, ".", fn _ ->
      (256 * :rand.uniform())
      |> Float.floor()
      |> trunc()
    end)
  end

  def type,
    do: :inet

  def cast(inet = %Postgrex.INET{}),
    do: {:ok, to_string(inet)}
  def cast(string) when is_binary(string) do
    case parse_address(string) do
      {:ok, _} ->
        {:ok, string}
      _ ->
        :error
    end
  end

  def cast(_) do
    :error
  end

  def load(inet = %Postgrex.INET{}),
    do: {:ok, to_string(inet)}
  def load(_),
    do: :error

  def dump(inet = %Postgrex.INET{}),
    do: {:ok, inet}
  def dump(string) when is_binary(string),
    do: parse_address(string)
  def dump(_),
    do: :error

  @spec parse_address(t) ::
    {:ok, Postgrex.INET.t}
    | :error
  defp parse_address(string) when is_binary(string) do
    string
    |> String.to_charlist()
    |> :inet.parse_ipv4strict_address()
    |> case do
      {:ok, address_tuple} ->
        {:ok, %Postgrex.INET{address: address_tuple}}
      {:error, :einval} ->
        :error
    end
  end

  def valid?(string) when is_binary(string) do
    parse_result =
      string
      |> String.to_charlist()
      |> :inet.parse_ipv4strict_address()

    match?({:ok, _}, parse_result)
  end
end
