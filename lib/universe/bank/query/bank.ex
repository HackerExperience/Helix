defmodule Helix.Universe.Bank.Query.Bank do

  alias Helix.Account.Model.Account
  alias Helix.Network.Model.Connection
  alias Helix.Universe.Bank.Action.Bank, as: BankAction
  alias Helix.Universe.Bank.Internal.BankAccount, as: BankAccountInternal
  alias Helix.Universe.Bank.Internal.BankToken, as: BankTokenInternal
  alias Helix.Universe.Bank.Internal.BankTransfer, as: BankTransferInternal
  alias Helix.Universe.Bank.Model.ATM
  alias Helix.Universe.Bank.Model.BankAccount
  alias Helix.Universe.Bank.Model.BankToken
  alias Helix.Universe.Bank.Model.BankTransfer

  @spec fetch_account(ATM.id, BankAccount.account) ::
    BankAccount.t
    | nil
  @doc """
  Fetches a bank account.
  """
  defdelegate fetch_account(atm, account_number),
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

  @spec get_account_token(BankAccount.t, Connection.idt) ::
    {:ok, BankToken.id}
    | {:error, Ecto.Changeset.t}
  @doc """
  Returns the token for the given (BankAccount, Connection) tuple.

  It generates a new one if it doesn't exists. It fetches the current one
  otherwise.

  Note that one bank account may have multiple tokens assigned to it at the
  same time. This happens when multiple connections are open (and hacked).

  One connection will always have a single token. So if two different attackers
  hack the same connection, they will acquire the same token.
  """
  def get_account_token(account, connection) do
    token = BankTokenInternal.fetch_by_connection(connection)
    if token do
      {:ok, token.token_id}
    else
      with {:ok, token} <- BankAction.generate_token(account, connection) do
        {:ok, token.token_id}
      end
    end
  end
end
