defmodule Helix.Software.Event.Cracker do

  import HELF.Flow
  import HELL.MacroHelpers

  alias Helix.Event
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Process.Model.Process
  alias Helix.Process.Query.Process, as: ProcessQuery
  alias Helix.Universe.Bank.Action.Bank, as: BankAction
  alias Helix.Universe.Bank.Model.BankToken
  alias Helix.Universe.Bank.Model.BankTransfer.BankTransferAbortedEvent
  alias Helix.Universe.Bank.Query.Bank, as: BankQuery
  alias Helix.Software.Model.SoftwareType.Cracker.Overflow.ConclusionEvent,
    as: OverflowConclusionEvent

  @spec overflow_conclusion(OverflowConclusionEvent.t) ::
    term
  @doc """
  Top-level handler of buffer overflow process conclusion.

  According to the process type, it will route to internal methods who are
  specialized on applying the overflow attack into that process/connection.

  Note that this function only handles the process *conclusion*. The actual
  notification of the overflow result to the user is done on more specific
  events, e.g. the `BankAccountPasswordRevealedEvent`.
  """
  def overflow_conclusion(event = %OverflowConclusionEvent{}) do
    process = ProcessQuery.fetch(event.target_process_id)

    case process.process_type do
      "wire_transfer" ->
        overflow_of_wire_transfer(process, event)
    end
  end

  @spec overflow_of_wire_transfer(Process.t, OverflowConclusionEvent.t) ::
    {:ok, BankToken.id}
    | term
  docp """
  Overflow attack on wire transfer generates an access token for the transfer's
  source account. Once the token is obtained, an event is emitted to notify the
  client.
  This function handles the conclusion of the event. Actual notification of the
  result (i.e. which token was obtained through the attack) is managed by other
  event handlers.
  """
  defp overflow_of_wire_transfer(process, event) do
    transfer_id = process.process_data.transfer_id
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

  # TODO: Waiting merge of PR 249 in order to implement OverflowFlow
  def bank_transfer_aborted(event = %BankTransferAbortedEvent{}) do
    ProcessQuery.get_processes_on_connection(event.connection_id)
  end
end
