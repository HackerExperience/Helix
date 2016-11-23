defmodule HELL.IPv6 do

  use Bitwise

  @twooctet 0xffff
  @meta_groups 3
  @rand_groups 8 - @meta_groups

  @spec generate([non_neg_integer]) :: String.t
  def generate(metadata) do
    metadata
    |> fill_metadata()
    |> Enum.concat(generate_octet_groups(@rand_groups))
    |> List.to_tuple()
    |> :inet.ntoa()
    |> List.to_string()
  end

  @spec generate_octet_groups(pos_integer) :: [0..65535]
  defp generate_octet_groups(groups) do
    try do
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
  end

  @spec partition_binary(String.t) :: [non_neg_integer]
  defp partition_binary(binary),
    do: partition_binary(binary, [])
  defp partition_binary(<<h1, h2, t::binary>>, acc),
    do: partition_binary(t, [h1 <<< 8 ||| h2| acc])
  defp partition_binary(<<>>, acc),
    do: acc

  @spec fill_metadata([non_neg_integer | String.t]) :: [non_neg_integer | String.t]
  defp fill_metadata(list),
    do: fill_metadata(list, 0)
  defp fill_metadata([], @meta_groups),
    do: []
  defp fill_metadata([h| t], n),
    do: [h| fill_metadata(t, n + 1)]
  defp fill_metadata([], n) when n < @meta_groups,
    do: [0x0000 | fill_metadata([], n + 1)]
end