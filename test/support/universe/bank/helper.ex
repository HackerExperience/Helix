defmodule Helix.Test.Universe.Bank.Helper do

  alias Helix.Universe.Bank.Model.BankTransfer

  alias HELL.TestHelper.Random
  alias Helix.Test.Server.Helper, as: ServerHelper

  @doc """
  Generates a random bank account number
  """
  def account_number,
    do: Random.number(min: 100_000, max: 999_999)

  @doc """
  Generates a random ATM ID
  """
  def atm_id,
    do: ServerHelper.id()

  @doc """
  Generates a random amount of money
  """
  def amount,
    do: Random.number(min: 1, max: 5000)

  def transfer_id,
    do: BankTransfer.ID.generate(%{}, {:bank, :transfer})
end
