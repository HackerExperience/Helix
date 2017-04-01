defmodule HELL.TestHelper.Random.Alphabet.Alphanum do
  @moduledoc """
  Alphabet with ascii letters and numbers

  The range of possible characters is
  `ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789`
  """

  alias HELL.TestHelper.Random.Alphabet

  @characters "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
  @alphabet Alphabet.build_alphabet(@characters)

  def alphabet,
    do: @alphabet
end