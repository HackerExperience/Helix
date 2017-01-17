defmodule HELL.PostgresTypes.LQuery do

  @behaviour Postgrex.Extension

  def init(opts) when opts in [:reference, :copy],
    do: opts

  def matching(_),
    do: [type: "lquery"]

  def format(_),
    do: :text

  def encode(_) do
    quote do
      bin when is_binary(bin) ->
        [<<byte_size(bin) :: signed-size(32)>> | bin]
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