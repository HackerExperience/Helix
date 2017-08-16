defmodule Helix.Universe.Bank.Model.BankTokenAcquiredEvent do
  @moduledoc false

  alias Helix.Universe.Bank.Model.ATM
  alias Helix.Universe.Bank.Model.BankAccount
  alias Helix.Universe.Bank.Model.BankToken

  @type t :: %__MODULE__{
    token_id: BankToken.id,
    atm_id: ATM.id,
    account_number: BankAccount.account
  }

  @enforce_keys ~w/token_id atm_id account_number/a
  defstruct ~w/token_id atm_id account_number/a
end
