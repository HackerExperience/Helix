defmodule Helix.Universe.Bank.Public.Index do

  alias Helix.Universe.Bank.Query.Bank, as: BankQuery
  alias Helix.Universe.Bank.Model.BankAccount

  @type index ::
    %{
      balance: BankAccount.balance
    }

  @type rendered_index ::
    %{
      balance: BankAccount.balance
    }

  @spec index(ATM.id, BankAccount.account) ::
    index

  @doc """
  Creates index for given BankAccount{atm_id, account_number}.
  """
  def index(atm_id, account_number) do
    bank_account = BankQuery.fetch_account(atm_id, account_number)
    balance = bank_account.balance

    %{
      balance: balance
    }
  end

  @spec render_index(index) ::
    rendered_index

  @doc """
  Renders index to client-friendly format.
  """
  def render_index(index),
    do: index
end
