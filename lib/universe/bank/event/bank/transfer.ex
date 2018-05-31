defmodule Helix.Universe.Bank.Event.Bank.Transfer do

  import Helix.Event

  event Processed do
    @moduledoc """
    BankTransferProcessedEvent is fired when a bank transfer process has
    completed its execution.
    """

    alias Helix.Network.Model.Connection
    alias Helix.Process.Model.Process
    alias Helix.Universe.Bank.Model.BankTransfer
    alias Helix.Universe.Bank.Process.Bank.Transfer, as: BankTransferProcess

    @type t ::
      %__MODULE__{
        transfer_id: BankTransfer.id,
        connection_id: Connection.id
      }

    event_struct [:transfer_id, :connection_id]

    @spec new(Process.t, BankTransferProcess.t) ::
      t
    def new(process = %Process{}, data = %BankTransferProcess{}) do
      %__MODULE__{
        transfer_id: data.transfer_id,
        connection_id: process.src_connection_id
      }
    end
  end

  event Aborted do
    @moduledoc """
    BankTransferAbortedEvent is fired when a bank transfer has been canceled or
    aborted.
    """

    alias Helix.Network.Model.Connection
    alias Helix.Process.Model.Process
    alias Helix.Process.Model.Process
    alias Helix.Universe.Bank.Model.BankTransfer
    alias Helix.Universe.Bank.Process.Bank.Transfer, as: BankTransferProcess

    @type t ::
      %__MODULE__{
        transfer_id: BankTransfer.id,
        connection_id: Connection.id
      }

    event_struct [:transfer_id, :started_by, :connection_id]

    @spec new(Process.t, BankTransferProcess.t) ::
      t
    def new(process = %Process{}, data = %BankTransferProcess{}) do
      %__MODULE__{
        transfer_id: data.transfer_id,
        started_by: data.started_by,
        connection_id: process.src_connection_id
      }
    end

    notify do

      alias Helix.Universe.Bank.Query.Bank, as: BankQuery

      @event :bank_transfer_aborted

      def generate_payload(event, _socket) do
        transfer = BankQuery.fetch_transfer(event.transfer_id)

        data =
          %{
            atm_id: to_string(transfer.atm_to),
            account_number: transfer.account_to,
            transfer_id: event.transfer_id
          }

        {:ok, data}
      end

      def whom_to_notify(event),
        do: %{account: event.started_by}
    end
  end

  event Successful do

    alias Helix.Universe.Bank.Model.BankAccount
    alias Helix.Universe.Bank.Model.BankTransfer
    alias Helix.Universe.Bank.Query.Bank, as: BankQuery

    @type t ::
      %__MODULE__{
        transfer: BankTransfer.t,
        account: BankAccount.t
      }

    event_struct [:transfer, :account]

    @spec new(BankTransfer.t) ::
      t
    def new(transfer = %BankTransfer{}) do
      account =
        BankQuery.fetch_account(transfer.atm_from, transfer.account_from)

      %__MODULE__{
        transfer: transfer,
        account: account
      }
    end

    notify do

      alias Helix.Universe.Bank.Query.Bank, as: BankQuery
      alias Helix.Universe.Bank.Public.Index, as: BankIndex

      @event :bank_transfer_successful

      def generate_payload(event, _socket) do
        transfer = BankIndex.render_transfer(event.transfer)

        data =
          %{
            transfer: transfer
          }

        {:ok, data}
      end

      def whom_to_notify(event) do
        transfer = BankQuery.fetch_transfer(event.transfer_id)
        %{
          account: transfer.started_by
        }
      end
    end
  end

  event Failed do

    alias Helix.Universe.Bank.Model.BankAccount
    alias Helix.Universe.Bank.Model.BankTransfer
    alias Helix.Universe.Bank.Query.Bank, as: BankQuery

    @type reason :: term

    @type t ::
      %__MODULE__{
        transfer: BankTransfer.t,
        account: BankAccount.t,
        reason: reason
      }

    event_struct [:transfer, :account, :reason]

    @spec new(BankTransfer.t, reason) ::
      t
    def new(transfer = %BankTransfer{}, reason) do
      account =
        BankQuery.fetch_account(transfer.atm_from, transfer.account_from)

      %__MODULE__{
        transfer: transfer,
        account: account,
        reason: reason
      }
    end

    notify do

      alias Helix.Universe.Bank.Public.Index, as: BankIndex

      @event :bank_transfer_failed

      def generate_payload(event, _socket) do
        data =
          %{
            transfer: BankIndex.render_transfer(event.transfer),
            reason: to_string(event.reason)
          }

        {:ok, data}
      end

      def whom_to_notify(event) do
        %{
          account: event.transfer.started_by
        }
      end
    end
  end
end
