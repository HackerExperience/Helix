defmodule Helix.Universe.Bank.Henforcer.Bank do

  import Helix.Henforcer

  alias Helix.Server.Model.Server
  alias Helix.Universe.Bank.Model.ATM
  alias Helix.Universe.Bank.Model.BankAccount
  alias Helix.Universe.Bank.Query.Bank, as: BankQuery

  @type account_exists_relay :: %{bank_account: BankAccount.t}
  @type account_exists_relay_partial :: %{}
  @type account_exists_error ::
    {false, {:bank_account, :not_found}, account_exists_relay_partial}

  @spec account_exists?(ATM.id, BankAccount.account) ::
    {true, account_exists_relay}
    | account_exists_error
  @doc """
  Henforces that the given bank account ({atm_id, account_number}) exists.
  """
  def account_exists?(atm_id = %Server.ID{}, account_number) do
    with bank_acc = %{} <- BankQuery.fetch_account(atm_id, account_number) do
      reply_ok(%{bank_account: bank_acc})
    else
      _ ->
        reply_error({:bank_account, :not_found})
    end
  end
end
