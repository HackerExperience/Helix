defmodule HELL.UUID do
  @moduledoc """
  Generates UUID v4 with custom format.
  The UUID follows v4 style, but is not compliant due to the custom header.
  The custom header is included to help with the debug process.
  """

  # allowed hex characters, hex is case sensitive, always use lowercased letters
  @hex_chars ?0..9
    |> Enum.to_list()
    |> Kernel.++(Enum.to_list(?a..?f))
    |> Enum.map(&List.wrap/1)
    |> Enum.map(&to_string/1)

  @doc """
  Generates UUID with given `domain`, `meta1` and `meta2`.
  Domain must always use two characters, metas must use just a single.
  The default value for metas is `0`.
  """
  def create(domain, opts \\ []) do
    with {:ok, header} <- header(domain, opts) do
      {:ok, merge(UUID.uuid4(), header)}
    end
  end

  @doc """
  Same as `create/2` but raises `ArgumentError` when header not valid.
  """
  def create!(domain, opts \\ []) do
    case create(domain, opts) do
      {:ok, id} -> id
      :error -> raise ArgumentError, "invalid uuid header"
    end
  end

  @doc """
  Parses the header, never use this with game logic, this is only for debug code or `iex` usage.
  """
  def debug(header) do
    <<domain::bytes-size(2), meta1::bytes-size(1), meta2::bytes-size(1), rest::binary>> = header
    %{domain: domain, meta1: meta1, meta2: meta2, uuid_part: rest}
  end

  @docp """
  Generates a valid header with given `domain`, `meta1` and `meta2`.
  Follow the same format rules from `create/2`.
  Useful for caching headers on module attributes, merge the header into an UUID later using
  `merge_header/1`.
  """
  defp header(domain, opts) do
    meta1 = Keyword.get(opts, :meta1, "0")
    meta2 = Keyword.get(opts, :meta2, "0")

    with true <- valid_domain?(domain),
         true <- valid_meta?(meta1),
         true <- valid_meta?(meta2) do
      {:ok, domain <> meta1 <> meta2}
    else
      _ -> :error
    end
  end

  @docp """
  Merges two strings together.
  """
  defp merge(uuid, prepend),
    do: merge(uuid, prepend, "")
  defp merge("-" <> uuid, prepend, acc),
    do: merge(uuid, prepend, acc <> "-")
  defp merge(<<_::utf8, uuid::binary>>, <<char::utf8, prepend::binary>>, acc),
    do: merge(uuid, prepend, <<acc::binary, char::utf8>>)
  defp merge(uuid, "", acc),
    do: acc <> uuid

  @docp """
  Validates meta attributes.
  Meta attributes must be a string composed of a single hexadecimal character.
  """
  for x <- @hex_chars do
    defp valid_meta?("#{unquote(x)}"),
      do: true
  end

  defp valid_meta?(_),
    do: false

  @docp """
  Validates domain name.
  Domain name must be a string composed of two hexadecimal characters.
  """
  for x <- @hex_chars, y <- @hex_chars do
    defp valid_domain?("#{unquote(x)}#{unquote(y)}"),
      do: true
  end

  defp valid_domain?(_),
    do: false
end
