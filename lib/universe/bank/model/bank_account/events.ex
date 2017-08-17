defmodule Helix.Universe.Bank.Model.BankAccount.RevealPassword.ConclusionEvent do
  @moduledoc false

  @enforce_keys ~w/token_id atm_id account_number/a
  defstruct ~w/token_id atm_id account_number/a
end

defmodule Helix.Universe.Bank.Model.BankAccount.PasswordRevealedEvent do
  @moduledoc false

  @type t :: %__MODULE__{
    atm_id: ATM.id,
    account_number: BankAccount.account,
    password: String.t
  }

  @enforce_keys ~w/atm_id account_number password/a
  defstruct ~w/atm_id account_number password/a
end
