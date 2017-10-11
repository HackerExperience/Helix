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
    alias Helix.Universe.Bank.Model.BankTransfer.ProcessType,
      as: BankTransferProcess

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
        connection_id: process.connection_id
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
    alias Helix.Universe.Bank.Model.BankTransfer.ProcessType,
      as: BankTransferProcess

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
        connection_id: process.connection_id
      }
    end
  end
end
