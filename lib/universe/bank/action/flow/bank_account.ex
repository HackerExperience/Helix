defmodule Helix.Universe.Bank.Action.Flow.BankAccount do

  import HELF.Flow

  alias Helix.Event
  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Network.Action.Flow.Tunnel, as: TunnelFlow
  alias Helix.Network.Query.Network, as: NetworkQuery
  alias Helix.Process.Model.Process
  alias Helix.Server.Model.Server
  alias Helix.Universe.Bank.Action.Bank, as: BankAction
  alias Helix.Universe.Bank.Model.BankAccount
  alias Helix.Universe.Bank.Model.BankToken
  alias Helix.Universe.Bank.Query.Bank, as: BankQuery

  alias Helix.Universe.Bank.Process.Bank.Account.AccountCreate,
    as: BankAccountCreateProcess
  alias Helix.Universe.Bank.Process.Bank.Account.AccountClose,
    as: BankAccountCloseProcess
  alias Helix.Universe.Bank.Process.Bank.Account.RevealPassword,
    as: BankAccountRevealPasswordProcess
  alias Helix.Universe.Bank.Process.Bank.Account.ChangePassword,
    as: BankAccountChangePasswordProcess

  @typep relay :: Event.relay

  @doc """
  Starts the `bank_reveal_password` process.

  This game mechanic happens on the ATM control panel, when an attacker has
  an account's token and want to "reveal" its password.

  It is a process managed by TOP, in the sense that the password reveal does
  not happen instantly. Completion is handled by `BankAccountEvent`.

  Emits: ProcessCreatedEvent
  """
  @spec reveal_password(
    BankAccount.t,
    BankToken.id,
    Server.t,
    Server.t,
    relay) ::
    {:ok, Process.t}
    | BankAccountRevealPasswordProcess.executable_error
  def reveal_password(account, token_id, gateway, atm, relay) do
    params = %{
      token_id: token_id,
      account: account
    }

    meta = %{
      network_id: NetworkQuery.internet().network_id,
      bounce: nil
    }

    BankAccountRevealPasswordProcess.execute(gateway, atm, params, meta, relay)
  end

  @spec open(Server.t, Account.id, Server.t, relay) ::
  {:ok, Process.t}
  | BankAccountChangeProcess.executable_error
  @doc """
  Starts the `bank_account_create` process.
  """
  def open(gateway, account_id, atm, relay) do
    entity_id = Entity.ID.cast!(to_string(account_id))
    atm_id = atm.server_id

    meta = %{
      network_id: NetworkQuery.internet().network_id,
      bounce: nil,
      source_entity_id: entity_id
    }

    BankAccountCreateProcess.execute(gateway, atm, %{atm_id: atm_id}, meta, relay)
  end

  @spec close(Server.t, BankAccount.t, Server.t, relay) ::
  {:ok, Process.t}
  | BankAccountCloseProcess.executable_error
  @doc """
  Starts the `bank_account_close` process.
  """
  def close(gateway, bank_account, atm, relay) do
    meta = %{
      network_id: NetworkQuery.internet().network_id,
      bounce: nil
    }

    params = %{
      atm_id: bank_account.atm_id,
      account_number: bank_account.account_number
    }

    BankAccountCloseProcess.execute(gateway, atm, params, meta, relay)
  end

  @spec change_password(BankAccount.t, Server.t, Server.t, relay) ::
  {:ok, Process.t}
  | BankAccountChangePasswordProcess.executable_error
  @doc """
  Starts the `bank_change_password` process.

  This game mechanic happens on the BankAccount control panel where the
  BankAccount's owner can change the BankAccount's Password

  It is a process managed by TOP. in the sense that the password change does not
  happen instantly. Completion is handled by `BankAccountEvent`.

  Emits: ProcessCreatedEvent
  """
  def change_password(account, gateway, atm, relay) do
    meta = %{
      network_id: NetworkQuery.internet().network_id,
      src_atm_id: atm.server_id,
      src_acc_number: account.account_number,
      bounce: nil
    }

    BankAccountChangePasswordProcess.execute(gateway, atm, %{}, meta, relay)
  end
  @doc """
  Logs into a bank account using a password. If the given password matches the
  current account password, the login is successful, in which case a BankLogin
  connection is created.

  Emits: BankAccountLoginEvent, (ConnectionStartedEvent)
  """
  def login_password(atm_id, account_number, gateway_id, bounce_id, password, relay) do
    acc = BankQuery.fetch_account(atm_id, account_number)
    entity = EntityQuery.fetch_by_server(gateway_id)

    start_connection = fn ->
      TunnelFlow.connect(
        NetworkQuery.internet(),
        gateway_id,
        atm_id,
        bounce_id,
        {:bank_login, login_connection_meta(acc)},
        nil
      )
    end

    flowing do
      with \
        true <- not is_nil(acc),
        {:ok, _, events} <- BankAction.login_password(acc, password, entity),
        on_success(fn -> Event.emit(events, from: relay) end),

        {:ok, tunnel, connection} <- start_connection.()
      do
        {:ok, tunnel, connection}
      end
    end
  end

  @doc """
  Logs into a bank account using a token. If the given token is valid (not
  expired) and belongs to the given account, the login is successful, in which
  case a BankLogin connection is created.

  Emits: BankAccountLoginEvent, (ConnectionStartedEvent)
  """
  def login_token(atm_id, account_number, gateway_id, bounce_id, token, relay) do
    acc = BankQuery.fetch_account(atm_id, account_number)
    entity = EntityQuery.fetch_by_server(gateway_id)

    start_connection = fn ->
      TunnelFlow.connect(
        NetworkQuery.internet(),
        gateway_id,
        atm_id,
        bounce_id,
        {:bank_login, login_connection_meta(acc)},
        nil
      )
    end

    flowing do
      with \
        true <- not is_nil(acc),
        {:ok, _, events} <- BankAction.login_token(acc, token, entity),
        on_success(fn -> Event.emit(events, from: relay) end),

        {:ok, tunnel, connection} <- start_connection.()
      do
        {:ok, tunnel, connection}
      end
    end
  end

  defp login_connection_meta(account) do
    %{
      "atm_id" => account.atm_id,
      "account_number" => account.account_number
    }
  end
end
