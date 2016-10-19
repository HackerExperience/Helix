defmodule HELL.UUID do
  alias HELL.UUID.Format, as: UFormat

  def create(domain, opts \\ []) do
    meta1 = Keyword.get(opts, :meta1, "")
    meta2 = Keyword.get(opts, :meta2, "")

    UFormat.validate(%{domain: domain, meta1: meta1, meta2: meta2})
    |> UFormat.join!()
    |> merge(UUID.uuid4())
  end

  def merge(prepend, uuid),
    do: merge(uuid, prepend, "")
  defp merge("-" <> uuid, prepend, acc),
    do: merge(uuid, prepend, acc <> "-")
  defp merge(<<_::utf8, uuid::binary>>, <<char::utf8, prepend::binary>>, acc),
    do: merge(uuid, prepend, <<acc::binary, char::utf8>>)
  defp merge(uuid, "", acc),
    do: acc <> uuid
  defp merge("", prepend, acc),
    do: acc <> prepend
end
