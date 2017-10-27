import Helix.Process

process Helix.Software.Process.Cracker.Bruteforce do
  @moduledoc """
  The BruteforceProcess is launched when a user wants to figure out the root
  password of the target server (identified by `target_server_ip` and
  `target_server_id`).
  """

  alias Helix.Network.Model.Network
  alias Helix.Software.Model.File

  process_struct [:target_server_ip]

  @process_type :cracker_bruteforce

  @type t ::
    %__MODULE__{
      target_server_ip: Network.ip
    }

  @typep creation_params ::
    %{
      target_server_ip: Network.ip
    }

  @type objective :: %{cpu: resource_usage}

  @type resources ::
    %{
      objective: objective,
      static: map,
      dynamic: [:cpu]
    }

  @typep resources_params ::
    %{
      cracker: File.t_of_type(:cracker),
      hasher: File.t_of_type(:hasher) | nil
    }

  @spec new(creation_params) ::
    t
  def new(%{target_server_ip: ip}) do
    %__MODULE__{
      target_server_ip: ip
    }
  end

  @spec resources(resources_params) ::
    resources
  def resources(params = %{cracker: %File{}, hasher: _}),
    do: get_resources params

  processable do
    @moduledoc """
    Defines the BruteforceProcess lifecycle behavior.
    """

    alias Helix.Network.Model.Network
    alias Helix.Software.Process.Cracker.Bruteforce, as: BruteforceProcess
    alias Helix.Software.Event.Cracker.Bruteforce.Processed,
      as: BruteforceProcessedEvent

    on_completion(data) do
      event = BruteforceProcessedEvent.new(process, data)

      {:ok, [event]}
    end

    def after_read_hook(data) do
      %BruteforceProcess{
        target_server_ip: data.target_server_ip
      }
    end
  end

  resourceable do
    @moduledoc """
    Defines how long a BruteforceProcess should take, resource usage, etc.
    """

    alias Helix.Software.Factor.File, as: FileFactor
    alias Helix.Software.Model.File
    alias Helix.Software.Process.Cracker.Bruteforce, as: BruteforceProcess

    @type params :: BruteforceProcess.objective_params

    @type factors ::
      %{
        :cracker => %{version: FileFactor.fact_version},
        optional(:hasher) => %{version: FileFactor.fact_version}
      }

    @doc """
    At first all we care about is the attacker's Cracker version and the
    victim's Hasher version (if any). In the future we'll probably want to add
    extra factors, like Boost/Skills.
    """
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
    @doc """
    BruteforceProcess only uses CPU.
    """
    cpu(%{hasher: nil}) do
      f.cracker.version.bruteforce
    end

    cpu(%{hasher: %File{}}) do
      f.cracker.version.bruteforce * f.hasher.version.password
    end

    static do
      %{
        paused: %{ram: 100},
        running: %{ram: 200}
      }
    end

    dynamic do
      [:cpu]
    end
  end

  executable do
    @moduledoc """
    Defines how a BruteforceProcess should be executed.
    """

    alias Helix.Software.Process.Cracker.Bruteforce, as: BruteforceProcess
    alias Helix.Software.Query.File, as: FileQuery

    @type params :: BruteforceProcess.creation_params

    @type meta ::
      %{
        :cracker => File.t,
        optional(atom) => term
      }

    resources(_, target, _, %{cracker: cracker}) do
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

  process_viewable do
    @moduledoc """
    Renders the BruteforceProcess. As of now, ignores any custom data and uses
    the default process renderer (defined at `ProcessViewHelper`)
    """

    @type data :: %{}

    render_empty_data()
  end
end
