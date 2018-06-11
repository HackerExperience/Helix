defmodule Helix.Universe.Bank.Event.AccountCreate do

  import Helix.Event

  event Processed do

    alias Helix.Entity.Model.Entity
    alias Helix.Process.Model.Process
    alias Helix.Universe.Bank.Model.ATM
    alias Helix.Universe.Bank.Process.Bank.Account.AccountCreate,
      as: AccountCreateProcess

    @type t :: %__MODULE__{
      atm_id: ATM.id,
      requester: Entity.id
    }

    event_struct [:atm_id, :requester]

    @spec new(ATM.id, Entity.idt) :: t

    def new(atm_id, entity = %Entity{}) do
      %__MODULE__{
        atm_id: atm_id,
        requester: entity.id
      }
    end

    def new(atm_id, entity_id = %Entity.ID{}),
      do: %__MODULE__{atm_id: atm_id, requester: entity_id}

    @spec new(Process.t, AccountCreateProcess.t) :: t
    def new(process = %Process{}, data = %AccountCreateProcess{}) do
      %__MODULE__{
        atm_id: process.data.atm_id,
        requester: process.source_entity_id
      }
    end
  end
end
