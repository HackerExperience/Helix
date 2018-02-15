import Helix.Process

process Helix.Software.Process.Virus.Collect do
  @moduledoc """
  `VirusCollectProcess` is the process responsible for rewarding players money
  based on their active viruses.

  The process holds information about a single virus, so when collecting `n`
  viruses, `n` process (and `n` connections) will be created.

  This process is mostly a thin wrapper, as it should be. Handling of completion
  is performed by `VirusHandler` once `VirusCollectProcessedEvent` is fired.
  """

  alias Helix.Universe.Bank.Model.BankAccount

  process_struct [:wallet]

  @process_type :virus_collect

  @type t ::
    %__MODULE__{
      wallet: term
    }

  @type resources ::
    %{
      objective: objective,
      l_dynamic: [:cpu],
      r_dynamic: [],
      static: map
    }

  @type objective ::
    %{cpu: resource_usage}

  @type creation_params ::
    %{
      wallet: term | nil,
      bank_account: BankAccount.t | nil
    }

  @type resources_params :: map

  @spec new(creation_params) ::
    t
  def new(%{wallet: wallet}) do
    %__MODULE__{
      wallet: wallet
    }
  end

  @spec resources(resources_params) ::
    resources
  def resources(params),
    do: get_resources params

  processable do

    alias Helix.Software.Event.Virus.Collect.Processed,
      as: VirusCollectProcessedEvent

    on_completion(process, data) do
      event = VirusCollectProcessedEvent.new(process, data)

      {:delete, [event]}
    end
  end

  resourceable do

    alias Helix.Software.Process.Virus.Collect, as: VirusCollectProcess

    @type params :: VirusCollectProcess.resources_params

    @type factors :: map

    get_factors(_params) do
    end

    cpu(_) do
      500
    end

    static do
      %{
        paused: %{ram: 10},
        running: %{ram: 20}
      }
    end

    dynamic do
      [:cpu]
    end
  end

  executable do

    alias Helix.Network.Model.Bounce
    alias Helix.Network.Model.Network
    alias Helix.Software.Model.File
    alias Helix.Software.Process.Virus.Collect, as: VirusCollectProcess

    @type params :: VirusCollectProcess.creation_params

    @type meta ::
      %{
        virus: File.t,
        network_id: Network.id,
        bounce: Bounce.idt | nil
      }

    resources(_, _, _params, _meta) do
      %{}
    end

    source_file(_, _, _, %{virus: virus}) do
      virus.file_id
    end

    source_connection(_, _, _, _) do
      {:create, :virus_collect}
    end

    target_bank_account(_, _, _, %{virus: %{software_type: :virus_miner}}) do
      nil
    end

    target_bank_account(_, _, %{bank_account: bank_acc}, _) do
      bank_acc
    end
  end

  process_viewable do

    @type data :: %{}

    render_empty_data()
  end
end
