defmodule HELL.ID do

  alias HELL.Random

  def generate(type) do
    "HEID" <> "-" <> type <> "-" <> Random.random_string(15)
  end
end
