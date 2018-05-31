defmodule Helix.Universe.Bank.Action.Bank do

  alias Helix.Account.Model.Account
  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Network.Model.Connection
  alias Helix.Network.Action.Tunnel, as: TunnelAction
  alias Helix.Server.Model.Server
  alias Helix.Universe.NPC.Query.NPC, as: NPCQuery
  alias Helix.Universe.Bank.Internal.BankAccount, as: BankAccountInternal
  alias Helix.Universe.Bank.Internal.BankToken, as: BankTokenInternal
  alias Helix.Universe.Bank.Internal.BankTransfer, as: BankTransferInternal
  alias Helix.Universe.Bank.Henforcer.Bank, as: BankHenforcer
  alias Helix.Universe.Bank.Model.ATM
  alias Helix.Universe.Bank.Model.BankAccount
  alias Helix.Universe.Bank.Model.BankToken
  alias Helix.Universe.Bank.Model.BankTransfer
  alias Helix.Universe.Bank.Query.Bank, as: BankQuery

  alias Helix.Network.Event.Connection.Closed, as: ConnectionClosedEvent
  alias Helix.Universe.Bank.Event.Bank.Account.Login, as: BankAccountLoginEvent
  alias Helix.Universe.Bank.Event.Bank.Account.Updated,
    as: BankAccountUpdatedEvent
  alias Helix.Universe.Bank.Event.Bank.Account.Password.Revealed,
    as: BankAccountPasswordRevealedEvent
  alias Helix.Universe.Bank.Event.Bank.Account.Password.Changed,
    as: BankAccountPasswordChangedEvent
  alias Helix.Universe.Bank.Event.Bank.Account.Token.Acquired,
    as: BankAccountTokenAcquiredEvent
  alias Helix.Universe.Bank.Event.Bank.Account.Removed,
    as: BankAccountRemovedEvent
  alias Helix.Universe.Bank.Event.Bank.Transfer.Successful,
    as: BankTransferSuccessfulEvent
  alias Helix.Universe.Bank.Event.Bank.Transfer.Failed,
    as: BankTransferFailedEvent

  @spec start_transfer(BankAccount.t, BankAccount.t, pos_integer, Account.idt) ::
    {:ok, BankTransfer.t}
    | {:error, {:funds, :insufficient}}
    | {:error, {:bank_account, :not_found}}
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
    {:ok, BankTransfer.t, [BankTransferSuccessfulEvent.t]}
    | {:error, term, [BankTransferFailedEvent.t]}
  @doc """
  Completes the transfer.

  In case of success, the transfer is removed from the database and the amount
  is transferred to the destination account.

  May fail if the given transfer is not found, or if an internal error happened
  during the transaction.

  This function should not be called directly by Public. Instead, it must be
  triggered by the BankTransferCompletedEvent.
  """
  def complete_transfer(transfer) do
    case BankTransferInternal.complete(transfer) do
      :ok ->
        {:ok, transfer, [BankTransferSuccessfulEvent.new(transfer)]}

      {:error, reason} ->
        {
          :error,
          reason,
          [BankTransferFailedEvent.new(transfer, reason)]
        }
    end
  end

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
    {:ok, BankAccount.t, [BankAccountUpdatedEvent.t]}
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

    case BankAccountInternal.create(owner, atm, bank) do
      {:ok, bank_acc} ->
        {:ok, bank_acc, [BankAccountUpdatedEvent.new(bank_acc, :created)]}

      error ->
        error
    end
  end

  @spec close_account(BankAccount.t) ::
    :ok
    | {:error, {:bank_account, :not_found}}
    | {:error, {:bank_account, :not_empty}}
  @doc """
  Closes a bank account.

  May fail if the account is invalid or not empty. In order to close an account,
  its balance must be empty.
  """
  def close_account(account) do
    case BankAccountInternal.close(account) do
      :ok ->
        {:ok, [BankAccountRemovedEvent.new(account)]}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec direct_deposit(BankAccount.t, BankAccount.amount) ::
    {:ok, BankAccount.t, [BankAccountUpdatedEvent.t]}
    | {:error, :internal}
  @doc """
  Performs a direct deposit of $`amount` into `account`.

  NOTE: This is a direct deposit, and is meant for internal mechanics only, like
  when the player collects money off of viruses, or when rewards of a mission
  should be sent to the player. Not to confuse with direct financial mechanics,
  like transferring moneys between player accounts, in which case the underlying
  `BankTransferProcess` should be used instead.
  """
  def direct_deposit(account, amount) do
    case BankAccountInternal.deposit(account, amount) do
      {:ok, account} ->
        {:ok, account, [BankAccountUpdatedEvent.new(account, :balance)]}

      error ->
        error
    end
  end

  @spec generate_token(BankAccount.t, Connection.idt, Entity.idt) ::
    {:ok, BankToken.t, [BankAccountTokenAcquiredEvent.t]}
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
  def generate_token(account, connection, attacker_id) do
    token = BankTokenInternal.fetch_by_connection(connection)

    token_result =
      if token do
        {:ok, token}
      else
        BankTokenInternal.generate(account, connection)
      end

    case token_result do
      {:ok, token} ->
        event = BankAccountTokenAcquiredEvent.new(account, token, attacker_id)

        {:ok, token, [event]}
      error ->
        error
    end
  end

  @spec reveal_password(BankAccount.t, BankToken.id, Entity.id) ::
    {:ok, String.t, [BankAccountPasswordRevealedEvent.t]}
    | {:error, {:token, :notfound}}
  @doc """
  Reveals a bank account password. In order for the password to be revealed, a
  valid token must be passed. A token may be acquired through BufferOverflow
  attacks on WireTransfer or BankLogin connections.
  """
  def reveal_password(account, token_id, revealed_by) do
    with \
      {true, relay} <- BankHenforcer.token_valid?(account, token_id)
    do
      event = BankAccountPasswordRevealedEvent.new(account, revealed_by)

      {:ok, account.password, [event]}
    else
      _ ->
        {:error, {:token, :notfound}}
    end
  end

  @spec change_password(BankAccount.t, Entity.id) ::
  {:ok, BankAccount.t, [BankAccountPasswordChangedEvent.t]}
   | {:error, :internal}
   def change_password(account, changed_by) do
     with {:ok, account} <- update_password(account) do
       event = BankAccountPasswordChangedEvent.new(account, changed_by)

       {:ok, account, [event]}
     else
      _ ->
        {:error, :internal}
     end
   end

  @spec update_password(BankAccount.t) ::
  {:ok, BankAccount.t}
  | {:error, :internal}
  defdelegate update_password(account),
    to: BankAccountInternal,
    as: :change_password

  @spec login_password(BankAccount.t, String.t, Entity.idt) ::
    {:ok, BankAccount.t, [BankAccountLoginEvent.t]}
    | term
  @doc """
  Logs into a bank account using a password. The given password must match the
  account one.

  Returns the relevant BankAccountLoginEvent. Used by `BankAccountFlow`.
  """
  def login_password(account, password, login_by) do
    with true <- account.password == password do
      event = BankAccountLoginEvent.new(account, login_by)

      {:ok, account, [event]}
    end
  end

  @doc """
  Logs into a bank account using a token. The token must be valid and belong to
  the given account.

  Returns the relevant BankAccountLoginEvent. Used by `BankAccountFlow`.
  """
  @spec login_token(BankAccount.t, BankToken.id, Entity.idt) ::
    {:ok, BankAccount.t, [BankAccountLoginEvent.t]}
    | term
  def login_token(account, token_id, login_by) do
    with \
      {true, relay} <- BankHenforcer.token_valid?(account, token_id)
    do
      event = BankAccountLoginEvent.new(account, login_by, token_id)

      {:ok, account, [event]}
    else
      {false, reason, _} ->
        {:error, reason}
    end
  end

  @spec logout(BankAccount.t, Server.idt) ::
    [ConnectionClosedEvent.t]
  @doc """
  Gateway_id will log out from the given account. The corresponding connection
  (if any) will be closed, and the ConnectionClosed event is passed upstream.
  """
  def logout(account, gateway_id) do
    filter = fn meta ->
      meta
      && meta["atm_id"] == to_string(account.atm_id)
      && meta["account_number"] == account.account_number
    end

    TunnelAction.close_connections_where(
      gateway_id,
      account.atm_id,
      :bank_login,
      filter)
  end
end
