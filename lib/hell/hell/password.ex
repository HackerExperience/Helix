defmodule HELL.Password do

  def generate(:server),
    do: Burette.Internet.password alpha: 8, digit: 4

  def generate(:bank_account),
    do: Burette.Internet.password alpha: 8
end
