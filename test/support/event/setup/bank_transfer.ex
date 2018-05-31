defmodule Helix.Test.Event.Setup.BankTransfer do

  alias Helix.Universe.Bank.Event.Bank.Transfer.Processed,
    as: BankTransferProcessedEvent
  alias Helix.Universe.Bank.Event.Bank.Transfer.Aborted,
    as: BankTransferAbortedEvent
  alias Helix.Universe.Bank.Event.Bank.Transfer.Successful,
    as: BankTransferSuccessfulEvent
  alias Helix.Universe.Bank.Event.Bank.Transfer.Failed,
    as: BankTransferFailedEvent

  def processed(process, transfer_proc),
    do: BankTransferProcessedEvent.new(process, transfer_proc)

  def aborted(process, transfer_proc),
    do: BankTransferAbortedEvent.new(process, transfer_proc)

  def successful(transfer_id),
    do: BankTransferSuccessfulEvent.new(transfer_id)

  def failed(transfer_id, reason),
    do: BankTransferFailedEvent.new(transfer_id, reason)

end
