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
    with {:ok, header} <- ip_head(domain, object, opts) do
      {:ok, "#{header}:#{ip_tail()}"}
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
  defp ip_head(domain, object, opts) do
    meta_a = Keyword.get(opts, :meta1, "00")
    meta_b = Keyword.get(opts, :meta2, "00")

    with true <- valid_info?(domain),
         true <- valid_info?(object),
         true <- valid_info?(meta_a),
         true <- valid_info?(meta_b) do
      {:ok, "#{domain}#{object}:#{meta_a}#{meta_b}"}
    else
      _ -> :error
    end
  end

  @docp """
  Generates a true random IPv6 tail.
  """
  defp ip_tail() do
    "#{ip_hex()}:#{ip_hex()}:#{ip_hex()}:#{ip_hex()}:#{ip_hex()}:#{ip_hex()}"
  end

  @docp """
  Generates a string with four random hex digits.
  """
  defp ip_hex() do
    :crypto.strong_rand_bytes(4)
    |> :erlang.binary_to_list()
    |> Enum.map(&(Enum.at(@hex_chars, rem(&1, 16))))
    |> List.to_string()
  end

  @docp """
  Validates header information.
  """
  for x <- @hex_chars, y <- @hex_chars do
    defp valid_info?("#{unquote(x)}#{unquote(y)}"),
      do: true
  end
  defp valid_info?(_),
    do: false
end