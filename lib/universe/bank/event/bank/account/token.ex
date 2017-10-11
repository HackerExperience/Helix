defmodule Helix.Universe.Bank.Event.Bank.Account.Token do

  import Helix.Event

  event Acquired do
    @moduledoc """
    BankAccountTokenAcquired event is fired when an attacker figures out the
    token of a bank account.
    """

    alias Helix.Entity.Model.Entity
    alias Helix.Universe.Bank.Model.BankAccount
    alias Helix.Universe.Bank.Model.BankToken

    @type t :: %__MODULE__{
      entity_id: Entity.id,
      token: BankToken.t,
      account: BankAccount.t
    }

    event_struct [:entity_id, :token, :account]

    @spec new(BankAccount.t, BankToken.t, Entity.id) ::
      t
    def new(account = %BankAccount{}, token = %BankToken{}, entity_id) do
      %__MODULE__{
        entity_id: entity_id,
        token: token,
        account: account
      }
    end
  end
end
