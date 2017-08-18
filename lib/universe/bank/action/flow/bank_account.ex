defmodule Helix.Universe.Bank.Action.Flow.BankAccount do

  import HELF.Flow

  alias Helix.Event
  alias Helix.Network.Query.Network, as: NetworkQuery
  alias Helix.Process.Action.Process, as: ProcessAction
  alias Helix.Process.Model.Process
  alias Helix.Server.Model.Server
  alias Helix.Universe.Bank.Model.ATM
  alias Helix.Universe.Bank.Model.BankAccount
  alias Helix.Universe.Bank.Model.BankAccount.RevealPassword.ProcessType,
    as: RevealPasswordProcessType
  alias Helix.Universe.Bank.Model.BankToken

  @doc """
  Starts the `bank_reveal_password` process.

  This game mechanic happens on the ATM control panel, when an attacker has
  an account's token and want to "reveal" its password.

  It is a process managed by TOP, in the sense that the password reveal does
  not happen instantly. Completion is handled by `BankAccountEvent`.
  """
  @spec reveal_password(ATM.id, BankAccount.account, BankToken.id, Server.idt) ::
    {:ok, Process.t}
    | ProcessAction.on_create_error
  def reveal_password(atm_id, account_number, token_id, gateway_id) do
    process_data = %RevealPasswordProcessType{
      token_id: token_id,
      atm_id: atm_id,
      account_number: account_number
    }

    params = %{
      gateway_id: gateway_id,
      target_server_id: atm_id,
      network_id: NetworkQuery.internet().network_id,
      objective: %{cpu: 1},
      process_data: process_data,
      process_type: "bank_reveal_password"
    }

    flowing do
      with \
        {:ok, process, events} <- ProcessAction.create(params),
        on_success(fn -> Event.emit(events) end)
      do
        {:ok, process}
      end
    end
  end
end
