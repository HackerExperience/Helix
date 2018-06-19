defmodule Helix.Universe.Bank.Query.Bank do

  alias Helix.Account.Model.Account
  alias Helix.Server.Model.Server
  alias Helix.Universe.Bank.Internal.BankAccount, as: BankAccountInternal
  alias Helix.Universe.Bank.Internal.BankToken, as: BankTokenInternal
  alias Helix.Universe.Bank.Internal.BankTransfer, as: BankTransferInternal
  alias Helix.Universe.Bank.Internal.ATM, as: ATMInternal
  alias Helix.Universe.Bank.Model.ATM
  alias Helix.Universe.Bank.Model.BankAccount
  alias Helix.Universe.Bank.Model.BankTransfer

  @spec fetch_account(ATM.id, BankAccount.account) ::
    BankAccount.t
    | nil
  @doc """
  Fetches a bank account.
  """
  defdelegate fetch_account(atm_id, account_number),
    to: BankAccountInternal,
    as: :fetch

  @spec fetch_transfer(BankTransfer.id) ::
    BankTransfer.t
  @doc """
  Fetches a bank transfer
  """
  defdelegate fetch_transfer(transfer_id),
    to: BankTransferInternal,
    as: :fetch

  defdelegate fetch_token(token_id),
    to: BankTokenInternal,
    as: :fetch

  def fetch_account_from_connection(connection) do
    atm_id = Server.ID.cast!(connection.meta["atm_id"])
    account_number = connection.meta["account_number"]

    fetch_account(atm_id, account_number)
  end

  defdelegate fetch_atm(atm_id),
    to: ATMInternal,
    as: :fetch

  @spec get_account_balance(BankAccount.t) ::
    non_neg_integer
  @doc """
  Returns the balance of a given bank account.

  If the account is not found, returns 0.
  """
  defdelegate get_account_balance(account),
    to: BankAccountInternal,
    as: :get_balance

  @spec get_accounts(Account.id) ::
    [BankAccount.t]
  @doc """
  Returns all accounts owned by the given user.

  Note that an "usufrutuário em vida" is also the bank account owner.
  """
  defdelegate get_accounts(owner),
    to: BankAccountInternal

  @spec get_total_funds(Account.id) ::
    non_neg_integer
  @doc """
  Returns the sum of the balance of all accounts owned by the given user.
  """
  defdelegate get_total_funds(owner),
    to: BankAccountInternal
end
