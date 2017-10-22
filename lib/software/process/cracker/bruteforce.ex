import Helix.Process

process Helix.Software.Process.Cracker.Bruteforce do
  @moduledoc false

  alias Helix.Network.Model.Network
  alias Helix.Software.Model.File

  @type t :: %__MODULE__{
    target_server_ip: Network.ip
  }

  process_struct [:target_server_ip]

  @process_type :cracker_bruteforce

  def new(%{target_server_ip: ip}) do
    %__MODULE__{
      target_server_ip: ip
    }
  end

  def objective(params = %{cracker: %File{}, hasher: _}),
    do: set_objective params

  process_type do

    alias Helix.Network.Model.Network
    alias Helix.Software.Process.Cracker.Bruteforce, as: BruteforceProcess
    alias Helix.Software.Event.Cracker.Bruteforce.Processed,
      as: BruteforceProcessedEvent

    def dynamic_resources(_),
      do: [:cpu]

    def minimum(_) do
      %{
        paused: %{ram: 500},
        running: %{ram: 500}
      }
    end

    def kill(_data, process, _) do
      unchange(process)

      {delete(process), []}
    end

    def state_change(data, process, _, :complete) do
      unchange(process)

      event = BruteforceProcessedEvent.new(process, data)

      {delete(process), [event]}
    end

    def state_change(_, process, _, _),
      do: {process, []}

    def conclusion(data, process),
      do: state_change(data, process, :running, :complete)

    def after_read_hook(data) do
      %BruteforceProcess{
        target_server_ip: data.target_server_ip
      }
    end
  end

  process_objective do

    alias Helix.Software.Factor.File, as: FileFactor
    alias Helix.Software.Model.File

    @type params :: term
    @type factors :: term

    get_factors(%{cracker: cracker, hasher: hasher}) do

      # Retrieves information about the cracker
      factor FileFactor, %{file: cracker},
        only: :version,
        as: :cracker

      # Retrieves information about the target's hasher (if any)
      factor FileFactor, %{file: hasher},
        if: not is_nil(hasher),
        only: :size,
        as: :hasher
    end

    # TODO: Testing and proper balance
    cpu(%{hasher: nil}) do
      f.cracker.version.bruteforce
    end

    cpu(%{hasher: %File{}}) do
      f.cracker.version.bruteforce * f.hasher.version.password
    end
  end

  process_viewable do

    @type data :: %{}

    render_empty_data()
  end

  executable do

    alias Helix.Software.Query.File, as: FileQuery

    @process Helix.Software.Process.Cracker.Bruteforce

    objective(_, target, _, %{cracker: cracker}) do
      hasher = FileQuery.fetch_best(target, :password)

      %{
        cracker: cracker,
        hasher: hasher
      }
    end

    file(_gateway, _target, _params, %{cracker: cracker}) do
      cracker.file_id
    end

    connection(_gateway, _target, _params, _meta) do
      {:create, :cracker_bruteforce}
    end
  end
end
