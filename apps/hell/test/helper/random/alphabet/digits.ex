defmodule HELL.TestHelper.Random.Alphabet.Digits do
  @moduledoc """
  Alphabet with nothing but numbers

  The possible characters are `0123456789`
  """

  alias HELL.TestHelper.Random.Alphabet

  @characters "0123456789"
  @alphabet Alphabet.build_alphabet(@characters)

  def alphabet,
    do: @alphabet
end