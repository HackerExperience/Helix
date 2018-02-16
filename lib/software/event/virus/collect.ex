defmodule Helix.Software.Event.Virus.Collect do

  import Helix.Event

  event Processed do
    @moduledoc """
    `VirusCollectProcessedEvent` is fired when a `VirusCollectProcess` has
    completed and we should collect the earnings of the virus identified by
    `file`.
    """

    alias Helix.Process.Model.Process
    alias Helix.Universe.Bank.Model.BankAccount
    alias Helix.Universe.Bank.Query.Bank, as: BankQuery
    alias Helix.Software.Model.File
    alias Helix.Software.Model.Virus
    alias Helix.Software.Query.File, as: FileQuery

    alias Helix.Software.Process.Virus.Collect, as: VirusCollectProcess

    event_struct [:file, :payment_info]

    @type t ::
      %__MODULE__{
        file: File.t,
        payment_info: Virus.payment_info
      }

    @spec new(Process.t, VirusCollectProcess.t) ::
      t
    def new(process = %Process{}, %VirusCollectProcess{wallet: nil}) do
      bank_account =
        BankQuery.fetch_account(process.tgt_atm_id, process.tgt_acc_number)

      do_new(process, bank_account, nil)
    end

    def new(process = %Process{}, %VirusCollectProcess{wallet: wallet}),
      do: do_new(process, nil, wallet)

    @spec do_new(Process.t, BankAccount.t | nil, term | nil) ::
      t
    defp do_new(process, bank_account, wallet) do
      %__MODULE__{
        file: FileQuery.fetch(process.src_file_id),
        payment_info: {bank_account, wallet}
      }
    end
  end
end
