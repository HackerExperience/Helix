defmodule HELL.UUID do

  @hex_validation ~r/^[0-9A-F]+$/i

  def create(domain_name, opts \\ []) do
    head = header(domain_name, opts)
    uuid = generate()
    merge(head, uuid)
  end

  def generate,
    do: UUID.uuid4()

  def header(domain_name, opts \\ []) do
    domain =
      domain_name
      |> do_validate(:domain, :length, &(validate_length(&1, min: 2, max: 2)))
      |> do_validate(:domain, :hex, &validate_hex/1)

    meta1 =
      Keyword.get(opts, :meta1, "")
      |> do_validate(:meta1, :hex, &validate_hex/1)

    meta2 =
      Keyword.get(opts, :meta2, "")
      |> do_validate(:meta2, :hex, &validate_hex/1)

    domain <> meta1 <> meta2
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

  defp do_validate(string, target_name, validation_name, fun) do
    if fun.(string) do
      string
    else
      throw {:invalid_uuid, target_name, validation_name}
    end
  end

  defp validate_length(string, params) do
    max = Keyword.get(params, :max, 0)
    min = Keyword.get(params, :min, 0)

    length = String.length(string)

    (max == 0 or length <= max) and (min == 0 or length >= min)
  end

  defp validate_hex(string),
    do: (string == "") or Regex.match?(@hex_validation, string)
end
