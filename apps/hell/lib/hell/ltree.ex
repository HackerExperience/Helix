defmodule HELL.LTree do

  @behaviour Ecto.Type

  @opaque t :: String.t

  def type,
    do: :ltree

  def cast(str) when is_binary(str) do
    if valid_path?(str) do
      {:ok, str}
    else
      :error
    end
  end

  def cast(_) do
    :error
  end

  def load(str) when is_binary(str),
    do: {:ok, str}

  def dump(str) when is_binary(str),
    do: {:ok, str}
  def dump(_),
    do: :error

  # A path is a collection of labels. This check tests simultaneously that the
  # path is valid, that the labels are valid and that the characters used are
  # valid
  def valid_path?(""), # Root node
    do: true
  def valid_path?(path) when is_binary(path),
    do: valid_path?(path, "")
  def valid_path?(_),
    do: false

  defp valid_path?("." <> rest, label),
    do: valid_label?(label) and valid_path?(rest, "")
  defp valid_path?(<<c::utf8, rest::binary>>, label),
    do: allowed_char?(<<c::utf8>>) and valid_path?(rest, label <> <<c::utf8>>)
  defp valid_path?("", label),
    do: valid_label?(label)

  # A label cannot be bigger than 256 bytes and cannot be empty
  def valid_label?(label),
    do: is_binary(label) and byte_size(label) <= 256 and label != ""

  @characters Enum.flat_map([?a..?z, ?A..?Z, ?0..?9, [?_]], &Enum.to_list/1)
  for char <- @characters, c = <<char::utf8>> do
    defp allowed_char?(unquote(c)),
      do: true
  end
  defp allowed_char?(_),
    do: false
end

defmodule HELL.Postgrex.LTree do

  @behaviour Postgrex.Extension

  # This implementation is based on the example code by fishcakez that can be
  # found on https://github.com/elixir-ecto/postgrex/commit/a417a6525280654ab33b6502eee7008bf8ed16ad
  # and on https://github.com/elixir-ecto/postgrex/commit/547fa505c86d22e130ec17622d9a753a91811cee

  def init(opts),
    do: Keyword.get(opts, :decode_copy, :copy)

  def matching(_state),
    do: [type: "ltree"]

  def format(_state),
    do: :text

  def encode(_state) do
    quote do
      bin when is_binary(bin) ->
        [<<byte_size(bin)::signed-size(32)>>| bin]
    end
  end

  def decode(:reference) do
    quote do
      <<len::signed-size(32), bin::binary-size(len)>> ->
        bin
    end
  end
  def decode(:copy) do
    quote do
      <<len::signed-size(32), bin::binary-size(len)>> ->
        :binary.copy(bin)
    end
  end
end
