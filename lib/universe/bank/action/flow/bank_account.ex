defmodule Helix.Universe.Bank.Action.Flow.BankAccount do

  import HELF.Flow

  alias Helix.Event
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Network.Action.Tunnel, as: TunnelAction
  alias Helix.Network.Query.Network, as: NetworkQuery
  alias Helix.Process.Model.Process
  alias Helix.Server.Model.Server
  alias Helix.Universe.Bank.Action.Bank, as: BankAction
  alias Helix.Universe.Bank.Model.BankAccount
  alias Helix.Universe.Bank.Process.Bank.Account.RevealPassword,
    as: BankAccountRevealPasswordProcess
  alias Helix.Universe.Bank.Model.BankToken
  alias Helix.Universe.Bank.Query.Bank, as: BankQuery

  @typep relay :: Event.relay

  @doc """
  Starts the `bank_reveal_password` process.

  This game mechanic happens on the ATM control panel, when an attacker has
  an account's token and want to "reveal" its password.

  It is a process managed by TOP, in the sense that the password reveal does
  not happen instantly. Completion is handled by `BankAccountEvent`.

  Emits: ProcessCreatedEvent
  """
  @spec reveal_password(BankAccount.t, BankToken.id, Server.t, Server.t, relay) ::
    {:ok, Process.t}
    | BankAccountRevealPasswordProcess.executable_error
  def reveal_password(account, token_id, gateway, atm, relay) do
    params = %{
      token_id: token_id,
      account: account
    }

    meta = %{
      network_id: NetworkQuery.internet().network_id,
      bounce: []
    }

    BankAccountRevealPasswordProcess.execute(gateway, atm, params, meta, relay)
  end

  @doc """
  Logs into a bank account using a password. If the given password matches the
  current account password, the login is successful, in which case a BankLogin
  connection is created.

  Emits: BankAccountLoginEvent, ConnectionStartedEvent
  """
  def login_password(atm_id, account_number, gateway_id, bounces, password) do
    acc = BankQuery.fetch_account(atm_id, account_number)
    entity = EntityQuery.fetch_by_server(gateway_id)

    start_connection = fn ->
      TunnelAction.connect(
        NetworkQuery.internet(),
        gateway_id,
        atm_id,
        bounces,
        :bank_login,
        login_connection_meta(acc)
      )
    end

    flowing do
      with \
        true <- not is_nil(acc),
        {:ok, _, events} <- BankAction.login_password(acc, password, entity),
        on_success(fn -> Event.emit(events) end),

        {:ok, connection, events} <- start_connection.(),
        on_success(fn -> Event.emit(events) end)
      do
        {:ok, connection}
      end
    end
  end

  @doc """
  Logs into a bank account using a token. If the given token is valid (not
  expired) and belongs to the given account, the login is successful, in which
  case a BankLogin connection is created.

  Emits: BankAccountLoginEvent, ConnectionStartedEvent
  """
  def login_token(atm_id, account_number, gateway_id, bounces, token) do
    acc = BankQuery.fetch_account(atm_id, account_number)
    entity = EntityQuery.fetch_by_server(gateway_id)

    start_connection = fn ->
      TunnelAction.connect(
        NetworkQuery.internet(),
        gateway_id,
        atm_id,
        bounces,
        :bank_login,
        login_connection_meta(acc)
      )
    end

    flowing do
      with \
        true <- not is_nil(acc),
        {:ok, _, events} <- BankAction.login_token(acc, token, entity),
          on_success(fn -> Event.emit(events) end),

        {:ok, connection, events} <- start_connection.(),
          on_success(fn -> Event.emit(events) end)
      do
        {:ok, connection}
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
