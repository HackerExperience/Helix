import Helix.Process

process Helix.Universe.Bank.Process.Bank.Transfer do

  alias Helix.Universe.Bank.Model.BankTransfer

  process_struct [:transfer_id, :amount]

  @process_type :wire_transfer

  @type t ::
    %__MODULE__{
      transfer_id: BankTransfer.id,
      amount: BankTransfer.amount
    }

  @spec new(BankTransfer.t) ::
    t
  def new(transfer = %BankTransfer{}) do
    %__MODULE__{
      transfer_id: transfer.transfer_id,
      amount: transfer.amount
    }
  end

  processable do

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

    on_kill(data, _reason) do
      event = BankTransferAbortedEvent.new(process, data)

      {:ok, [event]}
    end

    on_completion(data) do
      event = BankTransferProcessedEvent.new(process, data)

      {:ok, [event]}
    end

    def after_read_hook(data),
      do: data
  end
end
