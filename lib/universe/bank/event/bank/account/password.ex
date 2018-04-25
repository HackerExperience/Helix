defmodule Helix.Universe.Bank.Event.Bank.Account.Password do

  import Helix.Event

  event Revealed do

    alias Helix.Entity.Model.Entity
    alias Helix.Universe.Bank.Model.BankAccount

    @type t :: %__MODULE__{
      entity_id: Entity.id,
      account: BankAccount.t
    }

    event_struct [:entity_id, :account]

    @spec new(BankAccount.t, Entity.id) ::
      t
    def new(account = %BankAccount{}, entity_id) do
      %__MODULE__{
        entity_id: entity_id,
        account: account
      }
    end
  end

  event Changed do

   alias Helix.Entity.Model.Entity
   alias Helix.Universe.Bank.Model.BankAccount

   @type t :: %__MODULE__{
     entity_id: Entity.id,
     account: BankAccount.t
   }

   event_struct [:entity_id, :account]

   @spec new(BankAccount.t, Entity.id) ::
   t
   def new(account = %BankAccount{}, entity_id) do
     %__MODULE__{
       entity_id: entity_id,
       account: account
     }
   end
  end
end
