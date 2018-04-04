defmodule Helix.Universe.Bank.Public.Bank do

  alias Helix.Universe.Bank.Query.Bank, as: BankQuery
  alias Helix.Universe.Bank.Model.BankAccount
  alias Helix.Universe.Bank.Model.ATM

  #TODO: Add Transfer History
  @type bootstrap ::
    %{
      balance: BankAccount.balance
    }

  @type rendered_bootstrap ::
    %{
      balance: BankAccount.balance
    }

  @spec bootstrap({ATM.id, BankAccount.account}) ::
    bootstrap

  def bootstrap({atm_id, account_number}) do
    bank_account = BankQuery.fetch_account(atm_id, account_number)

    %{
      balance: bank_account.balance
    }
  end

  @spec render_bootstrap(bootstrap) ::
    rendered_bootstrap

  def render_bootstrap(bootstrap) do
    bootstrap
  end
end
