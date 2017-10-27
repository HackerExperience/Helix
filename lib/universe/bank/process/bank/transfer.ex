import Helix.Process

process Helix.Universe.Bank.Process.Bank.Transfer do

  alias Helix.Universe.Bank.Model.BankTransfer

  process_struct [:transfer_id, :amount]

  @process_type :wire_transfer

  @type t ::
    %__MODULE__{
      transfer_id: BankTransfer.id,
      amount: BankTransfer.amount
    }

  @typep creation_params ::
    %{
      transfer: BankTransfer.t
    }

  @type objective :: %{cpu: resource_usage}

  @type resources :: %{
    objective: objective,
    static: map,
    dynamic: []
  }

  @typep resources_params ::
    %{
      transfer: BankTransfer.t
    }

  @spec new(creation_params) ::
    t
  def new(%{transfer: transfer = %BankTransfer{}}) do
    %__MODULE__{
      transfer_id: transfer.transfer_id,
      amount: transfer.amount
    }
  end

  @spec resources(resources_params) ::
    resources
  def resources(params = %{transfer: %BankTransfer{}}),
    do: get_resources params

  processable do

    alias Helix.Universe.Bank.Event.Bank.Transfer.Aborted,
      as: BankTransferAbortedEvent
    alias Helix.Universe.Bank.Event.Bank.Transfer.Processed,
      as: BankTransferProcessedEvent

    on_kill(data, _reason) do
      event = BankTransferAbortedEvent.new(process, data)

      {:ok, [event]}
    end

    on_completion(data) do
      event = BankTransferProcessedEvent.new(process, data)

      {:ok, [event]}
    end

    def after_read_hook(data),
      do: data
  end

  resourceable do

    alias Helix.Universe.Bank.Process.Bank.Transfer, as: BankTransferProcess

    @type params :: BankTransferProcess.objective_params
    @type factors :: term

    get_factors(%{transfer: _}) do end

    # TODO: Use Time, not CPU
    cpu(%{transfer: transfer}) do
      transfer.amount
    end

    dynamic do
      []
    end

    # Review: Not exactly what I want. Where do I put limitations?
    # TODO: Add ResourceTime; specify to the size of the transfer.
    static do
      %{
        paused: %{ram: 50},
        running: %{ram: 100}
      }
    end
  end

  executable do

    alias Helix.Universe.Bank.Process.Bank.Transfer, as: BankTransferProcess

    @type params :: BankTransferProcess.creation_params
    @type meta :: term

    resources(_gateway, _atm, %{transfer: transfer}, _meta) do
      %{transfer: transfer}
    end

    connection(_gateway, _atm, _, _) do
      {:create, :wire_transfer}
    end
  end
end
