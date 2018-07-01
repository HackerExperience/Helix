defmodule Helix.ID.Utils do

  alias Helix.ID

  @type parsed_id ::
    %{
      grandparent: parse_data,
      parent: parse_data,
      timestamp: parse_data,
      object: parse_data,
      domain: parse_data
    }

  @typep parse_data :: %{bin: binary, dec: non_neg_integer}

  @spec parse(ID.id) ::
    parsed_id
  @doc """
  Parses the given `id`, displaying the binary and decimal value for each
  section (`grandparent`, `parent`, `timestamp`, `object` and `domain`).
  """
  def parse(id) do
    bin_id = id_to_bin(id)

    gp_bin = String.slice(bin_id, 0..23)
    p_bin = String.slice(bin_id, 24..53)
    t_bin = String.slice(bin_id, 54..83)
    o_bin = String.slice(bin_id, 84..119)
    d_bin = String.slice(bin_id, 120..128)

    gp_dec = Integer.parse(gp_bin, 2) |> elem(0)
    p_dec = Integer.parse(p_bin, 2) |> elem(0)
    t_dec = Integer.parse(t_bin, 2) |> elem(0)
    o_dec = Integer.parse(o_bin, 2) |> elem(0)
    d_dec = Integer.parse(d_bin, 2) |> elem(0)

    %{
      grandparent: %{bin: gp_bin, dec: gp_dec},
      parent: %{bin: p_bin, dec: p_dec},
      timestamp: %{bin: t_bin, dec: t_dec},
      object: %{bin: o_bin, dec: o_dec},
      domain: %{bin: d_bin, dec: d_dec}
    }
  end

  @spec id_to_bin(ID.id) ::
    binary
  @doc """
  Converts the given `id` into a binary string.
  """
  def id_to_bin(%_{id: id}),
    do: id_to_bin(id)
  def id_to_bin({grp1, grp2, grp3, grp4, grp5, grp6, grp7, grp8}) do
    (Integer.to_string(grp1, 2) |> String.pad_leading(16, "0")) <>
    (Integer.to_string(grp2, 2) |> String.pad_leading(16, "0")) <>
    (Integer.to_string(grp3, 2) |> String.pad_leading(16, "0")) <>
    (Integer.to_string(grp4, 2) |> String.pad_leading(16, "0")) <>
    (Integer.to_string(grp5, 2) |> String.pad_leading(16, "0")) <>
    (Integer.to_string(grp6, 2) |> String.pad_leading(16, "0")) <>
    (Integer.to_string(grp7, 2) |> String.pad_leading(16, "0")) <>
    (Integer.to_string(grp8, 2) |> String.pad_leading(16, "0"))
  end

  @spec bin_to_hex(binary, pos_integer) ::
    hex :: binary
  @doc """
  Converts the given `binary` string into an hexadecimal string.
  """
  def bin_to_hex(binary, size) do
    binary
    |> Integer.parse(2)
    |> elem(0)
    |> Integer.to_string(16)
    |> String.pad_leading(size, "0")
  end

  @spec hex_to_id(binary) ::
    ID.id
  @doc """
  Converts the given `hex` string into the internal ID (tuple) format.
  """
  def hex_to_id(hex) do
    {
      String.slice(hex, 0..15) |> Integer.parse(2) |> elem(0),
      String.slice(hex, 16..31) |> Integer.parse(2) |> elem(0),
      String.slice(hex, 32..47) |> Integer.parse(2) |> elem(0),
      String.slice(hex, 48..63) |> Integer.parse(2) |> elem(0),
      String.slice(hex, 64..79) |> Integer.parse(2) |> elem(0),
      String.slice(hex, 80..95) |> Integer.parse(2) |> elem(0),
      String.slice(hex, 96..111) |> Integer.parse(2) |> elem(0),
      String.slice(hex, 112..128) |> Integer.parse(2) |> elem(0)
    }
  end

  @spec random_bits(pos_integer) ::
    binary
  @doc """
  Generates `bits` random binary digits.
  """
  def random_bits(bits),
    do: HELL.Binary.random(bits)

  @spec modulo_for(pos_integer) ::
    pos_integer
  @doc """
  Returns the corresponding modulo for the given bit size (`value^2`).
  """
  def modulo_for(4),
    do: 16
  def modulo_for(8),
    do: 256
  def modulo_for(10),
    do: 1_024
  def modulo_for(11),
    do: 2_048
  def modulo_for(16),
    do: 65_536
  def modulo_for(19),
    do: 524_288
  def modulo_for(30),
    do: 1_073_741_824
end
