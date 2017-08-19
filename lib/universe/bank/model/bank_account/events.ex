defmodule \
  Helix.Universe.Bank.Model.BankAccount.RevealPassword.ConclusionEvent do
  @moduledoc false

  alias Helix.Server.Model.Server
  alias Helix.Universe.Bank.Model.ATM
  alias Helix.Universe.Bank.Model.BankAccount
  alias Helix.Universe.Bank.Model.BankToken

  @type t :: %__MODULE__{
    gateway_id: Server.id,
    token_id: BankToken.id,
    atm_id: ATM.id,
    account_number: BankAccount.account
  }

  @enforce_keys ~w/gateway_id token_id atm_id account_number/a
  defstruct ~w/gateway_id token_id atm_id account_number/a
end

defmodule Helix.Universe.Bank.Model.BankAccount.PasswordRevealedEvent do
  @moduledoc false

  alias Helix.Entity.Model.Entity
  alias Helix.Universe.Bank.Model.ATM
  alias Helix.Universe.Bank.Model.BankAccount

  @type t :: %__MODULE__{
    entity_id: Entity.id,
    atm_id: ATM.id,
    account_number: BankAccount.account,
    password: String.t
  }

  @enforce_keys ~w/entity_id atm_id account_number password/a
  defstruct ~w/entity_id atm_id account_number password/a
end

defmodule Helix.Universe.Bank.Model.BankAccount.LoginEvent do
  @moduledoc false

  alias Helix.Entity.Model.Entity
  alias Helix.Universe.Bank.Model.BankAccount

  @type t :: %__MODULE__{
    entity_id: Entity.id,
    account: BankAccount.t
  }

  @enforce_keys ~w/entity_id account/a
  defstruct ~w/entity_id account/a
end
