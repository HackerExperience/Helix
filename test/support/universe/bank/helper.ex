defmodule Helix.Test.Universe.Bank.Helper do

  alias HELL.TestHelper.Random
  alias Helix.Test.Server.Setup, as: ServerSetup

  @doc """
  Generates a random bank account number
  """
  def account_number,
    do: Random.number(min: 100_000, max: 999_999)

  @doc """
  Generates a random ATM ID
  """
  def atm_id,
    do: ServerSetup.id()

  @doc """
  Generates a random amount of money
  """
  def amount,
    do: Random.number(min: 1, max: 5000)
end
