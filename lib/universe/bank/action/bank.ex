defmodule Helix.Universe.Bank.Action.Bank do

  alias Helix.Account.Model.Account
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Network.Model.Connection
  alias Helix.Universe.NPC.Query.NPC, as: NPCQuery
  alias Helix.Universe.Bank.Internal.BankAccount, as: BankAccountInternal
  alias Helix.Universe.Bank.Internal.BankToken, as: BankTokenInternal
  alias Helix.Universe.Bank.Internal.BankTransfer, as: BankTransferInternal
  alias Helix.Universe.Bank.Model.ATM
  alias Helix.Universe.Bank.Model.BankAccount
  alias Helix.Universe.Bank.Model.BankAccount.PasswordRevealedEvent,
    as: BankAccountPasswordRevealedEvent
  alias Helix.Universe.Bank.Model.BankToken
  alias Helix.Universe.Bank.Model.BankTokenAcquiredEvent
  alias Helix.Universe.Bank.Model.BankTransfer
  alias Helix.Universe.Bank.Query.Bank, as: BankQuery

  @spec start_transfer(BankAccount.t, BankAccount.t, pos_integer, Account.idt) ::
    {:ok, BankTransfer.t}
    | {:error, {:funds, :insufficient}}
    | {:error, {:account, :notfound}}
    | {:error, Ecto.Changeset.t}
  @doc """
  Starts a bank transfer.

  In case of success, the transfer is started and the funds, specified by
  `amount`, are withdrawn from the source account.

  May fail if the given bank accounts are invalid or if the originating account
  does not have enough funds to perform the transaction.

  This function should not be called directly by Public. Instead,
  `BankTransferFlow.start()` should be use, which will take care of creating
  the transfer process as well.
  """
  defdelegate start_transfer(from_account, to_account, amount, started_by),
    to: BankTransferInternal,
    as: :start

  @spec complete_transfer(BankTransfer.t) ::
    :ok
    | {:error, {:transfer, :notfound}}
    | {:error, :internal}
  @doc """
  Completes the transfer.

  In case of success, the transfer is removed from the database and the amount
  is transferred to the destination account.

  May fail if the given transfer is not found, or if an internal error happened
  during the transaction.

  This function should not be called directly by Public. Instead, it must be
  triggered by the BankTransferCompletedEvent.
  """
  defdelegate complete_transfer(transfer),
    to: BankTransferInternal,
    as: :complete

  @spec abort_transfer(BankTransfer.t) ::
    :ok
    | {:error, {:transfer, :notfound}}
    | {:error, :internal}
  @doc """
  Aborts the transfer.

  In case of success, the transfer is removed from the database and the amount
  is transferred back to the source account.

  May fail if the given transfer is not found, or if an internal error happened
  during the transaction.

  This function should not be called directly by Public. Instead, it must be
  triggered by the BankTransferAbortedEvent.
  """
  defdelegate abort_transfer(transfer),
    to: BankTransferInternal,
    as: :abort

  @spec open_account(Account.idt, ATM.id) ::
    {:ok, BankAccount.t}
    | {:error, Ecto.Changeset.t}
  @doc """
  Opens a bank account.
  """
  def open_account(owner, atm) do
    bank =
      atm
      |> EntityQuery.fetch_by_server()
      |> Map.get(:entity_id)
      |> NPCQuery.fetch()

    %{owner_id: owner, atm_id: atm, bank_id: bank}
    |> BankAccountInternal.create()
  end

  @spec close_account(BankAccount.t) ::
    :ok
    | {:error, {:account, :notfound}}
    | {:error, {:account, :notempty}}
  @doc """
  Closes a bank account.

  May fail if the account is invalid or not empty. In order to close an account,
  its balance must be empty.
  """
  defdelegate close_account(account),
    to: BankAccountInternal,
    as: :close

  @spec generate_token(BankAccount.t, Connection.idt) ::
    {:ok, BankToken.t, [BankTokenAcquiredEvent.t]}
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
  def generate_token(account, connection) do
    token = BankTokenInternal.fetch_by_connection(connection)

    token_result =
      if token do
        {:ok, token.token_id}
      else
        with {:ok, token} <- BankTokenInternal.generate(account, connection) do
          {:ok, token.token_id}
        end
      end

    case token_result do
      {:ok, token} ->
        {:ok, token, [token_acquired_event(account, token)]}
      error ->
        error
    end
  end

  @spec token_acquired_event(BankAccount.t, BankToken.id) ::
    BankTokenAcquiredEvent.t
  defp token_acquired_event(account, token_id) do
    %BankTokenAcquiredEvent{
      token_id: token_id,
      atm_id: account.atm_id,
      account_number: account.account_number
    }
  end

  @spec reveal_password(BankAccount.t, BankToken.id) ::
    {:ok, String.t, [BankAccountPasswordRevealedEvent.t]}
    | {:error, {:token, :notfound}}
  def reveal_password(account, token_id) do
    password_revealed_event = fn account ->
      %BankAccountPasswordRevealedEvent{
        atm_id: account.atm_id,
        account_number: account.account_number,
        password: account.password
      }
    end

    with \
      token = %{} <- BankQuery.fetch_token(token_id),
      true <- account.account_number == token.account_number,
      true <- account.atm_id == token.atm_id
    do
      {:ok, account.password, [password_revealed_event.(account)]}
    else
      _ ->
        {:error, {:token, :notfound}}
    end
  end
end
