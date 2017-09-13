defmodule Helix.Universe.Bank.Model.BankAccount.RevealPassword.ProcessType do

  @enforce_keys ~w/token_id atm_id account_number/a
  defstruct ~w/token_id atm_id account_number/a

  defimpl Helix.Process.Model.Process.ProcessType do

    alias Ecto.Changeset
    alias Helix.Universe.Bank.Model.BankAccount.RevealPassword.ConclusionEvent,
      as: RevealPasswordConclusionEvent

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
      process =
        process
        |> Changeset.change()
        |> Map.put(:action, :delete)

      event = %RevealPasswordConclusionEvent{
        gateway_id: process.data.gateway_id,
        token_id: data.token_id,
        atm_id: data.atm_id,
        account_number: data.account_number
      }

      {process, [event]}
    end

    def conclusion(data, process),
      do: state_change(data, process, :running, :complete)

    def after_read_hook(data),
      do: data
  end
end
