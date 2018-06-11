defmodule Helix.Universe.Bank.Public.Bank do

  alias Helix.Event
  alias Helix.Account.Model.Account
  alias Helix.Server.Model.Server
  alias Helix.Network.Model.Tunnel
  alias Helix.Universe.Bank.Action.Flow.BankAccount,
    as: BankAccountFlow
  alias Helix.Universe.Bank.Action.Flow.BankTransfer,
    as: BankTransferFlow
  alias Helix.Universe.Bank.Public.Index, as: BankIndex
  alias Helix.Universe.Bank.Model.BankAccount
  alias Helix.Universe.Bank.Model.BankToken
  alias Helix.Universe.Bank.Model.ATM

  #TODO: Add Transfer History
  @type bootstrap :: BankIndex.index

  @type rendered_bootstrap :: BankIndex.rendered_index

  @spec bootstrap({ATM.id, BankAccount.account}) ::
    bootstrap
  @doc """
  Gets the BankAccount information and puts into a map.
  """
  def bootstrap({atm_id, account_number}) do
    BankIndex.index(atm_id, account_number)
  end

  @spec render_bootstrap(bootstrap) ::
    rendered_bootstrap

  @doc """
  Gets Bootstrap information and turns to client friendly format.
  """
  def render_bootstrap(bootstrap) do
    BankIndex.render_index(bootstrap)
  end

  @spec change_password(
    BankAccount.t,
    Server.t,
    Server.t,
    Event.relay
  ) ::
  {:ok, Process.t}
  | {:error, :internal}
  @doc """
  Starts a ChangePasswordProcess.
  """
  def change_password(account, gateway, atm, relay) do
    password_change =
      BankAccountFlow.change_password(account, gateway, atm, relay)
    case password_change do
      {:ok, process} ->
        {:ok, process}
      _ ->
        {:error, :internal}
    end
  end

  @spec reveal_password(
    BankAccount.t,
    BankToken.token_id,
    Server.t,
    Server.t,
    Event.relay
  ) ::
  {:ok, Process.t}
  | {:error, :internal}
  @doc """
  Starts a RevealPasswordProcess.
  """
  def reveal_password(bank_account, token, gateway, atm, relay) do
    BankAccountFlow.reveal_password(
      bank_account,
      token,
      gateway,
      atm,
      relay
      )
  end

  @spec open_account(Server.t, Account.id, Server.t, Event.relay) ::
  {:ok, BankAccount.t}
  | {:error, :internal}
  @doc """
  Opens a BankAccount on given atm to given account_id.
  """
  def open_account(gateway, account_id, atm, relay),
    do: BankAccountFlow.open(gateway, account_id, atm, relay)

  @spec close_account(Server.t, BankAccount.t, Server.t, Event.relay) ::
  :ok
  | {:error, {:bank_account, :not_found}}
  | {:error, {:bank_account, :not_empty}}
  @doc """
  Closes given account.
  """
  def close_account(gateway, account, atm, relay),
    do: BankAccountFlow.close(gateway, account, atm, relay)

  @spec transfer(
    BankAccount.t,
    BankAccount.t,
    BankAccount.amount,
    Account.t,
    Server.t,
    Tunnel.t,
    Event.relay
  ) ::
  {:ok, Process.t}
  | {:error, :internal}
  @doc """
  Starts a BankTransferProcess.
  """
  def transfer(
    from_account,
    to_account,
    amount,
    started_by,
    gateway,
    tunnel,
    relay)
    do
    transfer =
      BankTransferFlow.start(
        from_account,
        to_account,
        amount,
        started_by,
        gateway,
        tunnel,
        relay
      )

    case transfer do
      {:ok, process} ->
        {:ok, process}

      {:error, _} ->
        {:error, :internal}
    end
  end
end
