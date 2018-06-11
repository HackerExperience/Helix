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

    notify do

      @event :bank_password_revealed

      @doc false
      def generate_payload(event, _socket) do
        data =
          %{
            atm_id: event.account.atm_id,
            account_number: event.account.account_number,
            password: event.account.password
          }
      end

      def whom_to_notify(event),
        do: %{account: event.entity_id}
    end
  end

  event Changed do

    alias Helix.Entity.Model.Entity
    alias Helix.Universe.Bank.Model.BankAccount

    @type t :: %__MODULE__{
      account: BankAccount.t
    }

    event_struct [:account]

    @spec new(BankAccount.t) ::
    t
    def new(account = %BankAccount{}) do
      %__MODULE__{
        account: account
      }
    end

    notify do

      @event :bank_password_changed

      @doc false
      def generate_payload(event, _socket) do
        data =
          %{
            atm_id: event.account.atm_id,
            account_number: event.account.account_number,
            password: event.account.password
          }
      end

      def whom_to_notify(event),
        do: %{account: event.account.owner_id}
    end
  end
end
