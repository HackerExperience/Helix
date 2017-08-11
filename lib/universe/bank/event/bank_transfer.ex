defmodule Helix.Universe.Bank.Event.BankTransfer do

  alias Helix.Universe.Bank.Action.Bank, as: BankAction
  alias Helix.Universe.Bank.Model.BankTransfer.BankTransferAbortedEvent
  alias Helix.Universe.Bank.Model.BankTransfer.BankTransferCompletedEvent

  def transfer_completed(event = %BankTransferCompletedEvent{}),
    do: BankAction.complete_transfer(event.transfer_id)

  def transfer_aborted(event = %BankTransferAbortedEvent{}),
    do: BankAction.abort_transfer(event.transfer_id)
end
