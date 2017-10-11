defmodule Helix.Universe.Bank.Model.BankTransfer.ProcessType do

  alias Helix.Universe.Bank.Model.BankTransfer

  @type t ::
    %__MODULE__{
      transfer_id: BankTransfer.id,
      amount: BankTransfer.amount
    }

  @enforce_keys ~w/transfer_id amount/a
  defstruct ~w/transfer_id amount/a

  defimpl Helix.Process.Model.Process.ProcessType do

    import Helix.Process

    alias Helix.Universe.Bank.Event.Bank.Transfer.Aborted,
      as: BankTransferAbortedEvent
    alias Helix.Universe.Bank.Event.Bank.Transfer.Processed,
      as: BankTransferProcessedEvent

    def dynamic_resources(_),
      do: [:cpu]

    # Review: Not exactly what I want. Where do I put limitations?
    # TODO: Once TOP supports it, `minimum` should refer to raw time, not
    # hardware resources like cpu
    def minimum(_),
      do: %{}

    def kill(data, process, _) do
      unchange(process)

      event = BankTransferAbortedEvent.new(process, data)

      {delete(process), [event]}
    end

    def state_change(data, process, _, :complete) do
      unchange(process)

      event = BankTransferProcessedEvent.new(process, data)

      {delete(process), [event]}
    end

    def conclusion(data, process),
      do: state_change(data, process, :running, :complete)

    def after_read_hook(data),
      do: data
  end
end
