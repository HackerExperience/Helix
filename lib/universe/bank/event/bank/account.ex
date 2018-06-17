defmodule Helix.Universe.Bank.Event.Bank.Account do

  import Helix.Event

  event Updated do
    @moduledoc """
    `BankAccountUpdatedEvent` is fired when the underlying bank account has
    changed. It may happen either due to a balance update (most commonly) or due
    to a password change.
    """

    alias Helix.Universe.Bank.Model.BankAccount

    event_struct [:account, :reason]

    @type t ::
      %__MODULE__{
        account: BankAccount.t,
        reason: reason
      }

    @type reason :: :balance | :password

    @spec new(BankAccount.t, reason) ::
      t
    def new(account = %BankAccount{}, reason) do
      %__MODULE__{
        account: account,
        reason: reason
      }
    end

    publish do
      @moduledoc """
      Publishes to the Client that the bank account has updated, so it can
      properly update the local data.
      """

      @event :bank_account_updated

      @doc false
      def generate_payload(event, _socket) do
        data =
          %{
            atm_id: to_string(event.account.atm_id),
            account_number: event.account.account_number,
            balance: event.account.balance,
            password: event.account.password,
            reason: to_string(event.reason)
          }

        {:ok, data}
      end

      @doc false
      def whom_to_publish(event),
        do: %{account: event.account.owner_id}
    end
  end

  event Login do

    alias Helix.Entity.Model.Entity
    alias Helix.Universe.Bank.Model.BankAccount
    alias Helix.Universe.Bank.Model.BankToken

    event_struct [:entity_id, :account, :token_id]

    @type t :: %__MODULE__{
      entity_id: Entity.id,
      account: BankAccount.t,
      token_id: BankToken.id | nil
    }

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
