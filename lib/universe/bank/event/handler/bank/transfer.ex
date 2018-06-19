defmodule Helix.Universe.Bank.Event.Handler.Bank.Transfer do

  import HELF.Flow

  alias Helix.Event
  alias Helix.Universe.Bank.Action.Bank, as: BankAction
  alias Helix.Universe.Bank.Query.Bank, as: BankQuery
  alias Helix.Universe.Bank.Event.Bank.Transfer.Aborted,
    as: BankTransferAbortedEvent
  alias Helix.Universe.Bank.Event.Bank.Transfer.Processed,
    as: BankTransferProcessedEvent

  def transfer_processed(event = %BankTransferProcessedEvent{}) do
    transfer = BankQuery.fetch_transfer(event.transfer_id)
    flowing do
      with \
        {:ok, _transfer, events} <- BankAction.complete_transfer(transfer),
        on_success(fn -> Event.emit(events, from: event) end)
      do
        :ok
      end
    end
  end

  def transfer_aborted(event = %BankTransferAbortedEvent{}) do
    transfer = BankQuery.fetch_transfer(event.transfer_id)
    BankAction.abort_transfer(transfer)
  end
end
