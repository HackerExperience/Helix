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

    notify do

      @event :bank_token_acquired

      @doc false
      def generate_payload(event, _socket) do
        data =
          %{
            atm_id: to_string(event.account.atm_id),
            account_number: to_string(event.account.account_number),
            token_id: event.token.token_id
          }
      end

      @doc false
      def whom_to_notify(event),
        do: %{account: event.entity_id}
    end
  end
end
