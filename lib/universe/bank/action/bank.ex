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
  alias Helix.Universe.Bank.Model.ATM
  alias Helix.Universe.Bank.Model.BankAccount
  alias Helix.Universe.Bank.Model.BankToken
  alias Helix.Universe.Bank.Model.BankTokenAcquiredEvent
  alias Helix.Universe.Bank.Model.BankTransfer
  alias Helix.Universe.Bank.Query.Bank, as: BankQuery

  alias Helix.Network.Model.Connection.ConnectionClosedEvent
  alias Helix.Universe.Bank.Model.BankAccount.PasswordRevealedEvent,
    as: BankAccountPasswordRevealedEvent
  alias Helix.Universe.Bank.Model.BankAccount.LoginEvent,
    as: BankAccountLoginEvent

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

  @spec generate_token(BankAccount.t, Connection.idt, Entity.idt) ::
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
  def generate_token(account, connection, attacker_id) do
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
        {:ok, token, [token_acquired_event(account, token, attacker_id)]}
      error ->
        error
    end
  end

  @spec token_acquired_event(BankAccount.t, BankToken.id, Entity.idt) ::
    BankTokenAcquiredEvent.t
  defp token_acquired_event(account, token_id, entity_id) do
    %BankTokenAcquiredEvent{
      entity_id: entity_id,
      token_id: token_id,
      atm_id: account.atm_id,
      account_number: account.account_number
    }
  end

  @spec reveal_password(BankAccount.t, BankToken.id, Entity.t) ::
    {:ok, String.t, [BankAccountPasswordRevealedEvent.t]}
    | {:error, {:token, :notfound}}
  @doc """
  Reveals a bank account password. In order for the password to be revealed, a
  valid token must be passed. A token may be acquired through BufferOverflow
  attacks on WireTransfer or BankLogin connections.
  """
  def reveal_password(account, token_id, revealed_by) do
    password_revealed_event = fn account ->
      %BankAccountPasswordRevealedEvent{
        entity_id: revealed_by,
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
      {:ok, account, [account_login_event(account, login_by)]}
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
      token = %{} <- BankQuery.fetch_token(token_id),
      true <- token.account_number == account.account_number
    do
      {:ok, account, [account_login_event(account, login_by, token_id)]}
    end
  end

  @spec account_login_event(BankAccount.t, Entity.idt, BankToken.id | nil) ::
    BankAccountLoginEvent.t
  defp account_login_event(account, login_by, token \\ nil) do
    %BankAccountLoginEvent{
      entity_id: login_by,
      account: account,
      token_id: token
    }
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
