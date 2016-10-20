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
  Domain is must always use two characters, metas must use just a single.
  The default value for metas is `0`.
  """
  def create(domain, opts \\ []) do
    head = header(domain, opts)
    if head, do: merge_header(head), else: nil
  end

  @doc """
  Generates a valid header with given `domain`, `meta1` and `meta2`.
  Follow the same format rules from create.
  Useful for caching headers on module attributes, merge the header into an UUID later using
  `merge_header/1`.
  """
  def header(domain, opts \\ []) do
    meta1 = Keyword.get(opts, :meta1, "0")
    meta2 = Keyword.get(opts, :meta2, "0")

    with true <- valid_domain?(domain),
         true <- valid_meta?(meta1),
         true <- valid_meta?(meta2) do
      domain <> meta1 <> meta2
    else
      _ -> nil
    end
  end

  @doc """
  Merges a header into a new UUID, this won't validate the header so always use a header
  generated with `header/2`.
  """
  def merge_header(head),
    do: if head, do: merge(UUID.uuid4(), head), else: nil

  @doc """
  Parses the header, never use this to on game logic, this is only for debug code or IEX usage.
  """
  def parse(header) do
    <<domain::bytes-size(2), meta1::bytes-size(1), meta2::bytes-size(1), rest::binary>> = header
    %{domain: domain, meta1: meta1, meta2: meta2, uuid: rest}
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
  """
  for x <- @hex_chars do
    defp valid_meta?("#{unquote(x)}"),
      do: true
  end

  defp valid_meta?(_),
    do: false

  @docp """
  Validates domain name.
  """
  for x <- @hex_chars, y <- @hex_chars do
    defp valid_domain?("#{unquote(x)}#{unquote(y)}"),
      do: true
  end

  defp valid_domain?(_),
    do: false
end
