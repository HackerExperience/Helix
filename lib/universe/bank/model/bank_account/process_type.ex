defmodule Helix.Universe.Bank.Model.BankAccount.RevealPassword.ProcessType do

  alias Helix.Universe.Bank.Model.ATM
  alias Helix.Universe.Bank.Model.BankAccount
  alias Helix.Universe.Bank.Model.BankToken

  @type t ::
    %__MODULE__{
      token_id: BankToken.id,
      atm_id: ATM.id,
      account_number: BankAccount.account
    }

  @enforce_keys [:token_id, :atm_id, :account_number]
  defstruct [:token_id, :atm_id, :account_number]

  defimpl Helix.Process.Model.Process.ProcessType do

    import Helix.Process

    alias Ecto.Changeset
    alias Helix.Universe.Bank.Event.RevealPassword.Processed,
      as: RevealPasswordProcessedEvent

    def dynamic_resources(_),
      do: [:cpu]

    def minimum(_),
      do: %{}

    def kill(_, process, _) do
      process =
        process
        |> Changeset.change()
        |> Map.put(:action, :delete)

      {process, []}
    end

    def state_change(data, process, _, :complete) do
      unchange(process)

      event = RevealPasswordProcessedEvent.new(process, data)

      {delete(process), [event]}
    end

    def conclusion(data, process),
      do: state_change(data, process, :running, :complete)

    def after_read_hook(data),
      do: data
  end
end
