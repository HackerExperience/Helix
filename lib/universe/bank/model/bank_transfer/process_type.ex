defmodule Helix.Universe.Bank.Model.BankTransfer.ProcessType do

  @enforce_keys ~w/transfer_id amount/a
  defstruct ~w/transfer_id amount/a

  defimpl Helix.Process.Model.Process.ProcessType do

    alias Ecto.Changeset
    alias Helix.Universe.Bank.Model.BankTransfer.BankTransferAbortedEvent
    alias Helix.Universe.Bank.Model.BankTransfer.BankTransferCompletedEvent

    def dynamic_resources(_),
      do: [:cpu]

    # Review: Not exactly what I want. Where do I put limitations?
    # TODO: Once TOP supports it, `minimum` should refer to raw time, not
    # hardware resources like cpu
    def minimum(_),
      do: %{}

    def kill(data, process, _) do
      process =
        process
        |> Changeset.change()
        |> Map.put(:action, :delete)

      event = %BankTransferAbortedEvent{
        transfer_id: data.transfer_id,
        connection_id: process.data.connection_id
      }

      {process, [event]}
    end

    def state_change(data, process, _, :complete) do
      process =
        process
        |> Changeset.change()
        |> Map.put(:action, :delete)

      event = %BankTransferCompletedEvent{
        transfer_id: data.transfer_id,
        connection_id: process.data.connection_id
      }

      {process, [event]}
    end

    def conclusion(data, process),
      do: state_change(data, process, :running, :complete)

    def after_read_hook(data),
      do: data
  end
end
