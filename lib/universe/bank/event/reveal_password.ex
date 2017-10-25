defmodule Helix.Universe.Bank.Event.RevealPassword do

  import Helix.Event

  event Processed do

    alias Helix.Process.Model.Process
    alias Helix.Server.Model.Server
    alias Helix.Universe.Bank.Model.BankAccount
    alias Helix.Universe.Bank.Model.BankToken
    alias Helix.Universe.Bank.Process.Bank.Account.RevealPassword,
      as: RevealPasswordProcess
    alias Helix.Universe.Bank.Query.Bank, as: BankQuery

    @type t :: %__MODULE__{
      gateway_id: Server.id,
      token_id: BankToken.id,
      account: BankAccount.t
    }

    event_struct [:gateway_id, :token_id, :account]

    @spec new(BankAccount.t, Server.id, BankToken.id) ::
      t
    def new(account = %BankAccount{}, gateway_id, token_id) do
      %__MODULE__{
        gateway_id: gateway_id,
        token_id: token_id,
        account: account
      }
    end

    @spec new(Process.t, RevealPasswordProcess.t) ::
      t
    def new(process = %Process{}, data = %RevealPasswordProcess{}) do
      account = BankQuery.fetch_account(data.atm_id, data.account_number)

      %__MODULE__{
        gateway_id: process.gateway_id,
        token_id: data.token_id,
        account: account
      }
    end
  end
end
