defmodule Helix.Universe.Bank.Event.BankTransfer do

  alias Helix.Universe.Bank.Action.Bank, as: BankAction
  alias Helix.Universe.Bank.Query.Bank, as: BankQuery
  alias Helix.Universe.Bank.Model.BankTransfer.BankTransferAbortedEvent
  alias Helix.Universe.Bank.Model.BankTransfer.BankTransferCompletedEvent

  def transfer_completed(event = %BankTransferCompletedEvent{}) do
    transfer = BankQuery.fetch_transfer(event.transfer_id)
    BankAction.complete_transfer(transfer)
  end

  def transfer_aborted(event = %BankTransferAbortedEvent{}) do
    transfer = BankQuery.fetch_transfer(event.transfer_id)
    BankAction.abort_transfer(transfer)
  end
end
