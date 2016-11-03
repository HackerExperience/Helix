defmodule HELL.IP do
  # allowed hex characters, hex is case sensitive, always use lowercased letters
  @hex_chars ?0..?9
    |> Enum.to_list()
    |> Kernel.++(Enum.to_list(?a..?f))
    |> Enum.map(&List.wrap/1)
    |> Enum.map(&to_string/1)

  @doc """
  Generates IPv6 with a header built using given `domain`, `object`, `meta1` and `meta2`.
  Every header component must be two characters long and valid hexadecimal.
  The default value for metas is `00`.
  """
  def create(domain, object, opts \\ []) do
    with {:ok, header} <- header_groups(domain, object, opts) do
      {:ok, "#{header}:#{random_groups()}"}
    end
  end

  @doc """
  Same as `create/3` but raises `ArgumentError` when header is not valid.
  """
  def create!(domain, object, opts \\ []) do
    case create(domain, object, opts) do
      {:ok, id} -> id
      :error -> raise ArgumentError, "invalid header"
    end
  end

  @doc """
  Parses the IP, never use this with game logic, this is only for debug code or `iex` usage.
  """
  def debug(ip) do
    <<
      domain::bytes-size(2), object::bytes-size(2), ":",
      meta1::bytes-size(2), meta2::bytes-size(2), rest::binary>> = ip
    %{domain: domain, object: object, meta1: meta1, meta2: meta2, ip_part: rest}
  end

  @docp """
  Validates and generates the header.
  """
  defp header_groups(domain, object, opts) do
    meta_a = Keyword.get(opts, :meta1, "00")
    meta_b = Keyword.get(opts, :meta2, "00")

    with true <- valid_data?(domain),
         true <- valid_data?(object),
         true <- valid_data?(meta_a),
         true <- valid_data?(meta_b) do
      {:ok, "#{domain}#{object}:#{meta_a}#{meta_b}"}
    else
      _ -> :error
    end
  end

  @docp """
  Generates a string with 6 hexadecimal characters divided by colons.
  This string composes the IPv6 tail.
  """
  defp random_groups() do
    "#{group()}:#{group()}:#{group()}:#{group()}:#{group()}:#{group()}"
  end

  @docp """
  Generates a string that will compose a group from `random_groups/0`.
  The string is composed of four random hexadecimal digits.

  This function will primarily try to use `:crypto.strong_rand_bytes/1` and fallbacks to
  `:crypto.rand_uniform/2` when system entropy is too low.
  """
  defp group() do
    try do
      :crypto.strong_rand_bytes(4)
      |> :erlang.binary_to_list()
      |> Enum.map(&(Enum.at(@hex_chars, rem(&1, 16))))
      |> List.to_string()
    rescue
      :low_entropy ->
        1..4
        |> Enum.map(fn _ -> Enum.at(@hex_chars, :crypto.rand_uniform(0, 16)) end)
        |> List.to_string()
    end
  end

  @docp """
  Validates header information.
  """
  for x <- @hex_chars, y <- @hex_chars do
    defp valid_data?("#{unquote(x)}#{unquote(y)}"),
      do: true
  end
  defp valid_data?(_),
    do: false
end