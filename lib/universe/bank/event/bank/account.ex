defmodule Helix.Universe.Bank.Event.Bank.Account do

  import Helix.Event

  event Login do

    alias Helix.Entity.Model.Entity
    alias Helix.Universe.Bank.Model.BankAccount
    alias Helix.Universe.Bank.Model.BankToken

    @type t :: %__MODULE__{
      entity_id: Entity.id,
      account: BankAccount.t,
      token_id: BankToken.id | nil
    }

    event_struct [:entity_id, :account, :token_id]

    @spec new(BankAccount.t, Entity.id) ::
      t
    def new(account = %BankAccount{}, entity_id, token_id \\ nil) do
      %__MODULE__{
        entity_id: entity_id,
        account: account,
        token_id: token_id
      }
    end
  end
end
