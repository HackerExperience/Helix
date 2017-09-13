defmodule Helix.Universe.Bank.Model.BankTokenAcquiredEvent do
  @moduledoc false

  alias Helix.Entity.Model.Entity
  alias Helix.Universe.Bank.Model.ATM
  alias Helix.Universe.Bank.Model.BankAccount
  alias Helix.Universe.Bank.Model.BankToken

  @type t :: %__MODULE__{
    entity_id: Entity.id,
    token_id: BankToken.id,
    atm_id: ATM.id,
    account_number: BankAccount.account
  }

  @enforce_keys ~w/entity_id token_id atm_id account_number/a
  defstruct ~w/entity_id token_id atm_id account_number/a
end
