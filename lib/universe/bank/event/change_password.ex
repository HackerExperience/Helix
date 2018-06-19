defmodule Helix.Universe.Bank.Event.ChangePassword do

  import Helix.Event

  event Processed do

    alias Helix.Process.Model.Process
    alias Helix.Server.Model.Server
    alias Helix.Universe.Bank.Model.BankAccount
    alias Helix.Universe.Bank.Process.Bank.Account.ChangePassword,
      as: ChangePasswordProcess
    alias Helix.Universe.Bank.Query.Bank, as: BankQuery

    @type t :: %__MODULE__{
      gateway_id: Server.id,
      account: BankAccount.t
    }

    event_struct [:gateway_id, :account]

    @spec new(BankAccount.t, Server.id) ::
    t
    def new(account = %BankAccount{}, gateway_id) do
      %__MODULE__{
        gateway_id: gateway_id,
        account: account
      }
    end

    @spec new(Process.t, ChangePasswordProcess.t) ::
    t
    def new(process = %Process{}, _data = %ChangePasswordProcess{}) do
      atm_id = process.src_atm_id
      account_number = process.src_acc_number
      account = BankQuery.fetch_account(atm_id, account_number)

      %__MODULE__{
        gateway_id: process.gateway_id,
        account: account
      }
    end
  end
end
