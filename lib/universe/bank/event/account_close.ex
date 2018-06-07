defmodule Helix.Universe.Bank.Event.AccountClose do

  import Helix.Event

  event Processed do

    alias Helix.Process.Model.Process
    alias Helix.Universe.Bank.Model.ATM
    alias Helix.Universe.Bank.Model.BankAccount
    alias Helix.Universe.Bank.Process.Bank.Account.AccountClose,
      as: AccountCloseProcess

    @type t :: %__MODULE__{
      atm_id: ATM.id,
      account_number: BankAccount.account
    }

    event_struct [:atm_id, :account_number]

    @spec new(ATM.id, BankAccount.account) :: t

    def new(atm_id, account_number) do
      %__MODULE__{
        atm_id: atm_id,
        account_number: account_number
      }
    end

    @spec new(Process.t, AccountCloseProcess.t) :: t
    def new(process = %Process{}, data = %AccountCloseProcess{}) do
      %__MODULE__{
        atm_id: process.src_atm_id,
        account_number: process.src_acc_number
      }
    end
  end
