defmodule Helix.Software.Event.Handler.Cracker do

  import HELF.Flow
  import HELL.Macros

  alias Helix.Event
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Network.Query.Tunnel, as: TunnelQuery
  alias Helix.Process.Model.Process
  alias Helix.Process.Query.Process, as: ProcessQuery
  alias Helix.Server.Action.Server, as: ServerAction
  alias Helix.Server.Model.Server
  alias Helix.Universe.Bank.Action.Bank, as: BankAction
  alias Helix.Universe.Bank.Model.BankToken
  alias Helix.Universe.Bank.Query.Bank, as: BankQuery

  alias Helix.Universe.Bank.Event.Bank.Transfer.Aborted,
    as: BankTransferAbortedEvent
  alias Helix.Software.Event.Cracker.Bruteforce.Processed,
    as: BruteforceProcessedEvent
  alias Helix.Software.Event.Cracker.Overflow.Processed,
    as: OverflowProcessedEvent

  @spec bruteforce_conclusion(BruteforceProcessedEvent.t) ::
    {:ok, Server.password}
    | {:error, {:nip, :notfound}}
    | {:error, :internal}
  @doc """
  Callback executed when a bruteforce process is completed. It will attempt to
  retrieve the target server password, an in case of success will emit a new
  event that will 1) notify the client and 2) update the Database.

  Emits: ServerPasswordAcquiredEvent | CrackerBruteforceFailedEvent
  """
  def bruteforce_conclusion(event = %BruteforceProcessedEvent{}) do
    flowing do
      with \
        {:ok, password, events} <-
          ServerAction.crack(
            event.source_entity_id,
            event.target_server_id,
            event.network_id,
            event.target_server_ip
          ),
        on_success(fn -> Event.emit(events, from: event) end)
      do
        {:ok, password}
      else
        {:error, reason, events} ->
          Event.emit(events, from: event)
          {:error, reason}
      end
    end
  end

  @spec overflow_conclusion(OverflowProcessedEvent.t) ::
    term
  @doc """
  Top-level handler of buffer overflow process conclusion. An overflow attack
  may target a process or a connection.

  According to the process or connection type, it will route to internal methods
  who are specialized on applying the overflow attack into that specific
  process/connection.

  Note that this function only handles the process *conclusion*. The actual
  notification of the overflow result to the user is done on more specific
  events, e.g. the `BankTokenAcquiredEvent`.
  """
  def overflow_conclusion(
    event = %OverflowProcessedEvent{target_connection_id: nil})
  do
    process = ProcessQuery.fetch(event.target_process_id)

    case process.type do
      :wire_transfer ->
        overflow_of_wire_transfer(process, event)
    end
  end

  def overflow_conclusion(
    event = %OverflowProcessedEvent{target_process_id: nil})
  do
    connection = TunnelQuery.fetch_connection(event.target_connection_id)

    case connection.connection_type do
      :bank_login ->
        overflow_of_bank_login(connection, event)
    end
  end

  @spec overflow_of_wire_transfer(Process.t, OverflowProcessedEvent.t) ::
    {:ok, BankToken.t}
    | term
  docp """
  Overflow attack on wire transfer generates an access token for the transfer's
  source account. Once the token is obtained, an event is emitted to notify the
  client.
  This function handles the conclusion of the event. Actual notification of the
  result (i.e. which token was obtained through the attack) is managed by other
  event handlers.

  Emits: BankTokenAcquiredEvent.t
  """
  defp overflow_of_wire_transfer(process, event) do
    transfer_id = process.data.transfer_id
    connection_id = process.connection_id

    flowing do
      with \
        transfer = %{} <- BankQuery.fetch_transfer(transfer_id),
        account = %{} <-
          BankQuery.fetch_account(transfer.atm_from, transfer.account_from),
        attacker_id = %{} <- EntityQuery.fetch_by_server(event.gateway_id),
        {:ok, token, events} <-
           BankAction.generate_token(account, connection_id, attacker_id),
        on_success(fn -> Event.emit(events) end)
      do
        {:ok, token}
      end
    end
  end

  docp """
  Overflow attack on bank login connection generates an access token for the
  account. Once the token is obtained, an event is emitted to notify the client.
  This function handles the conclusion of the event. Actual notification of the
  result (i.e. which token was obtained through the attack) is managed by other
  event handlers.

  Emits: BankTokenAcquiredEvent.t
  """
  defp overflow_of_bank_login(connection, event) do
    connection_id = connection.connection_id

    flowing do
      with \
        account = %{} <-
          BankQuery.fetch_account_from_connection(connection),
        attacker_id = %{} <- EntityQuery.fetch_by_server(event.gateway_id),
        {:ok, token, events} <-
          BankAction.generate_token(account, connection_id, attacker_id),
        on_success(fn -> Event.emit(events) end)
      do
        {:ok, token}
      end
    end
  end

  # TODO: Waiting merge of PR 249 in order to implement OverflowFlow
  def bank_transfer_aborted(event = %BankTransferAbortedEvent{}) do
    ProcessQuery.get_processes_on_connection(event.connection_id)
  end
end
