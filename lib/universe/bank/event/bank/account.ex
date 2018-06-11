  defmodule Helix.Universe.Bank.Event.Bank.Account do

  import Helix.Event

  event Removed do

    alias Helix.Universe.Bank.Model.BankAccount

    event_struct [:account]

    @type t ::
      %__MODULE__{
        account: BankAccount.t
      }

    @spec new(BankAccount.t) ::
      t

    def new(account = %BankAccount{}) do
      %__MODULE__{
        account: account
      }
    end

    notify do

      @event :bank_account_removed

      @doc false
      def generate_payload(event, _socket) do
        data =
          %{
            atm_id: to_string(event.account.atm_id),
            account_number: event.account.account_number
          }

        {:ok, data}
      end

      @doc false
      def whom_to_notify(event),
        do: %{account: event.account.owner_id}
    end
  end

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

    @type reason :: :balance | :password | :created

    @spec new(BankAccount.t, reason) ::
      t
    def new(account = %BankAccount{}, reason) do
      %__MODULE__{
        account: account,
        reason: reason
      }
    end

    notify do
      @moduledoc """
      Notifies the client of the bank account update, so it can properly update
      the local data
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
      def whom_to_notify(event),
        do: %{account: event.account.owner_id}
    end
  end

  event Login do

    alias Helix.Account.Model.Account
    alias Helix.Entity.Model.Entity
    alias Helix.Entity.Query.Entity, as: EntityQuery
    alias Helix.Universe.Bank.Model.BankAccount
    alias Helix.Universe.Bank.Model.BankToken

    event_struct [:entity_id, :notify_owner, :account, :token_id]

    @type t :: %__MODULE__{
      entity_id: Entity.id,
      account: BankAccount.t,
      token_id: BankToken.id | nil
    }

    @spec new(BankAccount.t, Entity.idt) ::
      t
    def new(account, entity_or_entity_id, token_id \\ nil)
    def new(account = %BankAccount{}, entity = %Entity{}, token_id) do
      is_account? = entity.entity_type == :account

      %__MODULE__{
        entity_id: entity.entity_id,
        account: account,
        token_id: token_id,
        notify_owner: is_account?
      }
    end
    def new(account = %BankAccount{}, entity_id = %Entity.ID{}, token_id) do
      is_account? = EntityQuery.fetch(entity_id).entity_type == :account
      entity_id =
        if is_account? do
          %Account.ID{id: entity_id.id, root: Account}
        else
          entity_id
        end

      %__MODULE__{
        entity_id: entity_id,
        account: account,
        token_id: token_id,
        notify_owner: is_account?
      }
    end

    notify do
      @moduledoc """
      Notifies the client of bank account login, so it can properly update
      the local data.
      """

      @event :bank_login

      @doc false
      def generate_payload(event, _socket) do
        data =
          %{
            atm_id: to_string(event.account.atm_id),
            account_number: event.account.account_number,
            balance: event.account.balance,
            password: event.account.password
          }

        {:ok, data}
      end

      def whom_to_notify(event) do
        atm_id = event.account.atm_id
        bank_account = event.account.account_number

        entity_id =
          case event.entity_id do
            entity = %Entity{} ->
              %Account.ID{id: entity.entity_id.id, root: Account}
            entity_id = %Entity.ID{} ->
              %Account.ID{id: entity_id.id, root: Account}
          end

        base_map =
          %{
            bank_acc: [{atm_id, bank_account}]
          }

        if event.notify_owner do
          Map.merge(%{account: entity_id}, base_map)
        else
          base_map
        end
      end
    end
  end

  event Logout do

    alias Helix.Entity.Model.Entity
    alias Helix.Universe.Bank.Model.BankAccount

    event_struct [:account, :entity_id]

    @type t :: %__MODULE__{
      account: BankAccount.t,
      entity_id: Entity.id
    }

    @spec new(BankAccount.t, Entity.id) ::
      t
    def new(account = %BankAccount{}, entity_id = %Entity.ID{}) do
      %__MODULE__{
        account: account,
        entity_id: entity_id
      }
    end

    notify do

      @event :bank_logout

      def generate_payload(event, _socket) do
        data =
          %{
            atm_id: to_string(event.account.atm_id),
            account_number: event.account.account_number
          }

        {:ok, data}
      end

      def whom_to_notify(event),
        do: %{account: event.entity_id}
    end
  end
end
