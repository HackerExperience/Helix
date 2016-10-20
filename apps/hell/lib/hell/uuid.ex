defmodule HELL.UUID do

  @hex_chars ?0..9
    |> Enum.to_list()
    |> Kernel.++(Enum.to_list(?a..?f))
    |> Enum.map(&List.wrap/1)
    |> Enum.map(&to_string/1)

  def create(domain_name, opts \\ []) do
    head = header(domain_name, opts)
    if head, do: merge_header(head), else: nil
  end

  def merge_header(head),
    do: if head, do: merge(UUID.uuid4(), head), else: nil

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

  defp merge(uuid, prepend),
    do: merge(uuid, prepend, "")
  defp merge("-" <> uuid, prepend, acc),
    do: merge(uuid, prepend, acc <> "-")
  defp merge(<<_::utf8, uuid::binary>>, <<char::utf8, prepend::binary>>, acc),
    do: merge(uuid, prepend, <<acc::binary, char::utf8>>)
  defp merge(uuid, "", acc),
    do: acc <> uuid
  defp merge("", prepend, acc),
    do: acc <> prepend
    
  for x <- @hex_chars do
    defp valid_meta?("#{unquote(x)}"),
      do: true
  end

  defp valid_meta?(_),
    do: false

  for x <- @hex_chars, y <- @hex_chars do
    defp valid_domain?("#{unquote(x)}#{unquote(y)}"),
      do: true
  end

  defp valid_domain?(_),
    do: false
end
