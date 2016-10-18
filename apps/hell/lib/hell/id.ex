defmodule HELL.ID do
  alias HELL.Random, as: HRandom

  def generate(type) do
    "HEID" <> "-" <> type <> "-" <> HRandom.random_string(15)
  end
end
